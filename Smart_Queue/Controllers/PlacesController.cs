using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;

using Microsoft.Extensions.Caching.Memory;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PlacesController : ControllerBase
{
    private readonly SmartQueueDbContext _db;
    private readonly IMemoryCache _cache;

    public PlacesController(SmartQueueDbContext db, IMemoryCache cache)
    {
        _db = db;
        _cache = cache;
    }

    /// <summary>
    /// Get places with optional filtering by category, state, city, and search query.
    /// Supports pagination with page and pageSize parameters.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? category,
        [FromQuery] string? state,
        [FromQuery] string? city,
        [FromQuery] string? q,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var query = _db.Places.AsNoTracking().AsQueryable();

        if (!string.IsNullOrEmpty(category) && category != "All")
            query = query.Where(p => p.Category == category);

        if (!string.IsNullOrEmpty(q))
            query = query.Where(p => p.Name.Contains(q) || p.City.Contains(q) || p.State.Contains(q));

        var dbPlaces = await query.ToListAsync();

        if (!string.IsNullOrEmpty(state))
            dbPlaces = dbPlaces.Where(p => CleanAndTitleCase(p.State) == state).ToList();

        if (!string.IsNullOrEmpty(city))
            dbPlaces = dbPlaces.Where(p => CleanAndTitleCase(p.City) == city).ToList();

        var totalCount = dbPlaces.Count;

        var paginatedPlaces = dbPlaces
            .OrderBy(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var places = paginatedPlaces.Select(p => new PlaceDto
        {
            Id = p.Id,
            Name = CleanAndTitleCase(p.Name),
            Category = p.Category,
            State = CleanAndTitleCase(p.State),
            City = CleanAndTitleCase(p.City),
            Address = p.Address,
            Rating = p.Rating,
        }).ToList();

        return Ok(new
        {
            totalCount,
            page,
            pageSize,
            places,
        });
    }

    /// <summary>
    /// Get distinct list of states that have places for a given category.
    /// </summary>
    [HttpGet("states")]
    public async Task<IActionResult> GetStates()
    {
        var cacheKey = "states_All";
        
        if (!_cache.TryGetValue(cacheKey, out List<string>? states))
        {
            var rawStates = await _db.Places.AsNoTracking()
                .Select(p => p.State)
                .Distinct()
                .ToListAsync();

            states = rawStates
                .Select(CleanAndTitleCase)
                .Where(s => !string.IsNullOrEmpty(s))
                .Distinct()
                .OrderBy(s => s)
                .ToList();

            _cache.Set(cacheKey, states, TimeSpan.FromHours(24));
        }

        return Ok(states);
    }

    /// <summary>
    /// Get distinct list of cities for a given state.
    /// </summary>
    [HttpGet("cities")]
    public async Task<IActionResult> GetCities([FromQuery] string state)
    {
        var cacheKey = $"cities_{state}";

        if (!_cache.TryGetValue(cacheKey, out List<string>? cities))
        {
            var rawPlaces = await _db.Places.AsNoTracking().ToListAsync();

            cities = rawPlaces
                .Where(p => CleanAndTitleCase(p.State) == state)
                .Select(p => p.City)
                .Select(CleanAndTitleCase)
                .Where(c => !string.IsNullOrEmpty(c))
                .Distinct()
                .OrderBy(c => c)
                .ToList();

            _cache.Set(cacheKey, cities, TimeSpan.FromHours(24));
        }

        return Ok(cities);
    }

    /// <summary>
    /// Get a specific place by ID, mapped to a provider-like structure for the UI.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var place = await _db.Places.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
        if (place == null) return NotFound();

        var providerInfo = new
        {
            id = place.Id.ToString(),
            name = CleanAndTitleCase(place.Name),
            category = place.Category,
            address = $"{CleanAndTitleCase(place.City)}, {CleanAndTitleCase(place.State)}",
            rating = place.Rating,
            distanceKm = 2.5,
            activeQueueCount = 0,
            estimatedWaitMinutes = 0,
            services = place.Category == "Restaurant"
                ? new[]
                {
                    new { id = Guid.NewGuid().ToString(), name = "Table for 1-2", description = "Standard seating for couple", avgDurationMinutes = 45, cost = 0, isActive = true },
                    new { id = Guid.NewGuid().ToString(), name = "Table for 3-4", description = "Standard seating for up to 4", avgDurationMinutes = 60, cost = 0, isActive = true },
                    new { id = Guid.NewGuid().ToString(), name = "Family Table (5+)", description = "Large seating area", avgDurationMinutes = 90, cost = 0, isActive = true },
                }
                : new[]
                {
                    new {
                        id = Guid.NewGuid().ToString(),
                        name = "General Service",
                        description = "Standard queue service",
                        avgDurationMinutes = 15,
                        cost = 0,
                        isActive = true
                    }
                }
        };

        return Ok(providerInfo);
    }

    private static string CleanAndTitleCase(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return string.Empty;

        var clean = input.Trim().ToLower();
        
        // Fix dataset variants/duplicates for Dadra & Nagar Haveli
        if (clean.Contains("dadar and nagar haveli") || clean.Contains("dadra and nagar haveli"))
        {
            clean = "dadra and nagar haveli and daman and diu";
        }
        
        // Optional: Fix Delhi vs New Delhi if needed, but let's just stick to the obvious ones.

        var words = clean.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
        for (int i = 0; i < words.Length; i++)
        {
            if (words[i].Length > 0)
                words[i] = char.ToUpper(words[i][0]) + words[i].Substring(1);
        }
        return string.Join(" ", words);
    }
}
