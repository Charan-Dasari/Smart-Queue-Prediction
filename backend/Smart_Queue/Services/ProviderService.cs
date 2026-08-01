using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using ServiceProvider = Smart_Queue.Models.ServiceProvider;

namespace Smart_Queue.Services;

public class ProviderService
{
    private readonly SmartQueueDbContext _db;

    public ProviderService(SmartQueueDbContext db) => _db = db;

    /// <summary>
    /// Create a new provider and auto-generate admin credentials
    /// </summary>
    public async Task<(ProviderDto Provider, string AdminEmail, string AdminPassword)> CreateProviderAsync(CreateProviderRequest request)
    {
        var place = await _db.Places.FirstOrDefaultAsync(p => p.Id == request.PlaceId);
        if (place == null)
        {
            throw new Exception("Place not found in the dataset.");
        }

        // Check if it's already a provider
        var existingProvider = await _db.ServiceProviders.FirstOrDefaultAsync(p => p.Id == request.PlaceId);
        if (existingProvider != null)
        {
            throw new Exception("This business has already been onboarded.");
        }

        // Parse category from Place.Category string (e.g. "Hospital" -> ServiceCategory.Hospital)
        if (!Enum.TryParse<ServiceCategory>(place.Category, true, out var serviceCategory))
        {
            serviceCategory = ServiceCategory.Other;
        }

        var provider = new ServiceProvider
        {
            Id = place.Id, // Exact same ID as Place!
            Name = place.Name,
            Category = serviceCategory,
            Address = $"{place.City}, {place.State}",
            Rating = place.Rating,
            IsActive = true,
        };

        _db.ServiceProviders.Add(provider);

        // Auto-generate admin
        var sanitizedName = new string(place.Name.Where(c => char.IsLetterOrDigit(c)).ToArray()).ToLower();
        var adminEmail = $"{sanitizedName}admin@intelliq.com";
        var adminPassword = $"{sanitizedName}@123";

        var adminUser = new User
        {
            Name = $"{place.Name} Admin",
            Email = adminEmail,
            Mobile = "+91 99900 00000",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword),
            Role = UserRole.Admin,
            ProviderId = provider.Id,
        };

        _db.Users.Add(adminUser);
        await _db.SaveChangesAsync();

        var dto = new ProviderDto
        {
            Id = provider.Id,
            Name = provider.Name,
            Category = provider.Category,
            Address = provider.Address,
            Rating = provider.Rating,
            IsActive = provider.IsActive,
            AdminEmail = adminEmail,
            CreatedAt = provider.CreatedAt,
        };

        return (dto, adminEmail, adminPassword);
    }

    /// <summary>
    /// Delete a provider and all associated users
    /// </summary>
    public async Task<bool> DeleteProviderAsync(Guid providerId)
    {
        var provider = await _db.ServiceProviders.FindAsync(providerId);
        if (provider == null) return false;

        // Remove associated users (admins, staff)
        var associatedUsers = await _db.Users
            .Where(u => u.ProviderId == providerId)
            .ToListAsync();
        _db.Users.RemoveRange(associatedUsers);

        _db.ServiceProviders.Remove(provider);
        await _db.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Get all providers with live queue stats
    /// </summary>
    public async Task<List<ProviderDto>> GetAllProvidersAsync(string? category = null, string? query = null)
    {
        var q = _db.ServiceProviders.AsQueryable();

        if (!string.IsNullOrEmpty(category) && Enum.TryParse<ServiceCategory>(category, true, out var cat))
            q = q.Where(p => p.Category == cat);

        if (!string.IsNullOrEmpty(query))
            q = q.Where(p => p.Name.Contains(query));

        var providers = await q.ToListAsync();

        var result = new List<ProviderDto>();
        foreach (var p in providers)
        {
            var queueCount = await _db.QueueTokens
                .CountAsync(t => t.ProviderId == p.Id && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving));

            var avgWait = 0.0;
            if (queueCount > 0)
            {
                var waitMinutes = await _db.QueueTokens
                    .Where(t => t.ProviderId == p.Id && t.Status == AppointmentStatus.InQueue)
                    .Select(t => t.EstimatedWaitMinutes)
                    .ToListAsync();
                avgWait = waitMinutes.Count > 0 ? waitMinutes.Average() : 0;
            }

            // Get admin email
            var adminEmail = await _db.Users
                .Where(u => u.Role == UserRole.Admin && u.ProviderId == p.Id)
                .Select(u => u.Email)
                .FirstOrDefaultAsync();

            result.Add(new ProviderDto
            {
                Id = p.Id,
                Name = p.Name,
                Category = p.Category,
                Address = p.Address,
                Rating = p.Rating,
                IsActive = p.IsActive,
                ActiveQueueCount = queueCount,
                EstimatedWaitMinutes = (int)avgWait,
                AdminEmail = adminEmail,
                CreatedAt = p.CreatedAt,
            });
        }

        return result;
    }

    /// <summary>
    /// Get provider details with services
    /// </summary>
    public async Task<ProviderWithServicesDto?> GetProviderWithServicesAsync(Guid providerId)
    {
        var provider = await _db.ServiceProviders
            .Include(p => p.Services)
            .FirstOrDefaultAsync(p => p.Id == providerId);

        if (provider == null) return null;

        var services = provider.Services.Select(s => new ServiceDto
        {
            Id = s.Id,
            Name = s.Name,
            Description = s.Description,
            AvgDurationMinutes = s.AvgDurationMinutes,
            Cost = s.Cost,
            IsActive = s.IsActive,
            ProviderId = s.ProviderId,
        }).ToList();

        if (provider.Category == ServiceCategory.Restaurant && services.Count == 0)
        {
            var newServices = new List<Service>
            {
                new Service { Id = Guid.NewGuid(), Name = "Table for 1-2", Description = "Standard seating for couple", AvgDurationMinutes = 45, Cost = 0, IsActive = true, ProviderId = providerId },
                new Service { Id = Guid.NewGuid(), Name = "Table for 3-4", Description = "Standard seating for up to 4", AvgDurationMinutes = 60, Cost = 0, IsActive = true, ProviderId = providerId },
                new Service { Id = Guid.NewGuid(), Name = "Family Table (5+)", Description = "Large seating area", AvgDurationMinutes = 90, Cost = 0, IsActive = true, ProviderId = providerId },
            };
            
            _db.Services.AddRange(newServices);
            await _db.SaveChangesAsync();

            services = newServices.Select(s => new ServiceDto
            {
                Id = s.Id, Name = s.Name, Description = s.Description, AvgDurationMinutes = s.AvgDurationMinutes, Cost = s.Cost, IsActive = s.IsActive, ProviderId = s.ProviderId
            }).ToList();
        }
        else if (services.Count == 0)
        {
            var newServices = new List<Service>
            {
                new Service { Id = Guid.NewGuid(), Name = "General Service", Description = "Standard queue service", AvgDurationMinutes = 15, Cost = 0, IsActive = true, ProviderId = providerId }
            };

            _db.Services.AddRange(newServices);
            await _db.SaveChangesAsync();

            services = newServices.Select(s => new ServiceDto
            {
                Id = s.Id, Name = s.Name, Description = s.Description, AvgDurationMinutes = s.AvgDurationMinutes, Cost = s.Cost, IsActive = s.IsActive, ProviderId = s.ProviderId
            }).ToList();
        }

        return new ProviderWithServicesDto
        {
            Id = provider.Id,
            Name = provider.Name,
            Category = provider.Category,
            Address = provider.Address,
            Rating = provider.Rating,
            IsActive = provider.IsActive,
            CreatedAt = provider.CreatedAt,
            Services = services,
        };
    }
}
