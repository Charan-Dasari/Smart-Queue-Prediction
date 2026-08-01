using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Smart_Queue.Models;
using System.Text.Json;
using System.Globalization;

namespace Smart_Queue.Services;

public class GeoapifyService : IPoiService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly string _apiKey;

    public GeoapifyService(HttpClient httpClient, IMemoryCache cache, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _cache = cache;
        // User provided the key directly in chat, but ideally it should be in config.
        _apiKey = configuration["Geoapify:ApiKey"] ?? "769e023acf304eb1b4490cfff118ba1e";
    }

    public async Task<List<Smart_Queue.Models.ServiceProvider>> GetNearbyPoisAsync(double lat, double lon, double radiusMeters = 5000)
    {
        var cacheKey = $"geoapify_pois_{Math.Round(lat, 2)}_{Math.Round(lon, 2)}_{radiusMeters}";
        
        if (_cache.TryGetValue(cacheKey, out List<Smart_Queue.Models.ServiceProvider>? cachedPois))
        {
            return cachedPois ?? new List<Smart_Queue.Models.ServiceProvider>();
        }

        var categories = "healthcare,finance.bank,finance.atm,education.college,education.university,office.government,building.government,catering.restaurant,catering.fast_food,catering.cafe,accommodation.hotel,accommodation.motel";
        var filter = $"circle:{lon.ToString(CultureInfo.InvariantCulture)},{lat.ToString(CultureInfo.InvariantCulture)},{radiusMeters}";
        var bias = $"proximity:{lon.ToString(CultureInfo.InvariantCulture)},{lat.ToString(CultureInfo.InvariantCulture)}";
        
        var url = $"https://api.geoapify.com/v2/places?categories={categories}&filter={filter}&bias={bias}&limit=50&apiKey={_apiKey}";

        string json;
        try 
        {
            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();
            json = await response.Content.ReadAsStringAsync();
        } 
        catch (Exception ex)
        {
            Console.WriteLine($"Geoapify API Error: {ex.Message}");
            return new List<Smart_Queue.Models.ServiceProvider>();
        }

        using var doc = JsonDocument.Parse(json);
        var features = doc.RootElement.GetProperty("features").EnumerateArray();

        var pois = new List<Smart_Queue.Models.ServiceProvider>();

        foreach (var feature in features)
        {
            if (feature.TryGetProperty("properties", out var props) && props.TryGetProperty("name", out var nameProp))
            {
                var name = nameProp.GetString();
                if (string.IsNullOrWhiteSpace(name)) continue;

                // Geoapify uses unique string IDs, we'll hash it or generate one for OsmNodeId compatibility
                long id = props.TryGetProperty("place_id", out var idProp) ? idProp.GetString()?.GetHashCode() ?? 0 : Guid.NewGuid().GetHashCode();
                
                double nodeLat = props.GetProperty("lat").GetDouble();
                double nodeLon = props.GetProperty("lon").GetDouble();

                // Determine category based on Geoapify categories array
                var cats = props.TryGetProperty("categories", out var catsProp) ? 
                    catsProp.EnumerateArray().Select(c => c.GetString() ?? "").ToList() : 
                    new List<string>();

                var category = DetermineCategory(cats);

                var street = props.TryGetProperty("street", out var st) ? st.GetString() : "";
                var suburb = props.TryGetProperty("suburb", out var su) ? su.GetString() : "";
                var city = props.TryGetProperty("city", out var ct) ? ct.GetString() : "";
                var state = props.TryGetProperty("state", out var sta) ? sta.GetString() : "";
                
                var addressParts = new[] { street, suburb, city, state }.Where(s => !string.IsNullOrEmpty(s)).ToList();
                var address = string.Join(", ", addressParts);
                
                if (string.IsNullOrEmpty(address)) {
                    address = $"{Math.Round(nodeLat, 4)}, {Math.Round(nodeLon, 4)}";
                }

                var poi = new Smart_Queue.Models.ServiceProvider
                {
                    OsmNodeId = id,
                    Name = name,
                    Category = category,
                    Address = address,
                    Latitude = nodeLat,
                    Longitude = nodeLon,
                    Rating = Math.Round(3.5 + (new Random((int)id).NextDouble() * 1.5), 1)
                };
                
                pois.Add(poi);
            }
        }

        _cache.Set(cacheKey, pois, TimeSpan.FromHours(24));
        return pois;
    }

    private ServiceCategory DetermineCategory(List<string> categories)
    {
        if (categories.Any(c => c.StartsWith("healthcare"))) return ServiceCategory.Hospital;
        if (categories.Any(c => c.StartsWith("finance"))) return ServiceCategory.Bank;
        if (categories.Any(c => c.StartsWith("education"))) return ServiceCategory.College;
        if (categories.Any(c => c.StartsWith("office.government") || c.StartsWith("building.government"))) return ServiceCategory.GovtOffice;
        if (categories.Any(c => c.StartsWith("catering"))) return ServiceCategory.Restaurant;
        if (categories.Any(c => c.StartsWith("accommodation"))) return ServiceCategory.Hotel;
        
        return ServiceCategory.Other;
    }
}
