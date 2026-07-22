using Microsoft.Extensions.Caching.Memory;
using Smart_Queue.Models;
using System.Text.Json;
using System.Globalization;

namespace Smart_Queue.Services;

public class OsmService : IPoiService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;

    public OsmService(HttpClient httpClient, IMemoryCache cache)
    {
        _httpClient = httpClient;
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "SmartQueueApp/1.0");
        _cache = cache;
    }

    public async Task<List<Smart_Queue.Models.ServiceProvider>> GetNearbyPoisAsync(double lat, double lon, double radiusMeters = 5000)
    {
        var cacheKey = $"osm_pois_{Math.Round(lat, 2)}_{Math.Round(lon, 2)}_{radiusMeters}";
        
        if (_cache.TryGetValue(cacheKey, out List<Smart_Queue.Models.ServiceProvider>? cachedPois))
        {
            return cachedPois ?? new List<Smart_Queue.Models.ServiceProvider>();
        }

        // Overpass QL query to find amenities around the location
        // Using anchored regex for faster matching and nwr to get nodes/ways/relations
        var query = $@"[out:json][timeout:15];
            (
              nwr(around:{radiusMeters},{lat.ToString(CultureInfo.InvariantCulture)},{lon.ToString(CultureInfo.InvariantCulture)})[""amenity""~""^(hospital|clinic|bank|atm|university|college|townhall|courthouse|public_building|restaurant|cafe|fast_food)$""];
              nwr(around:{radiusMeters},{lat.ToString(CultureInfo.InvariantCulture)},{lon.ToString(CultureInfo.InvariantCulture)})[""tourism""~""^(hotel|motel)$""];
            );
            out center;";

        string json;
        try 
        {
            var content = new FormUrlEncodedContent(new[] { new KeyValuePair<string, string>("data", query) });
            var response = await _httpClient.PostAsync("https://overpass-api.de/api/interpreter", content);
            response.EnsureSuccessStatusCode();
            json = await response.Content.ReadAsStringAsync();
        } 
        catch (Exception ex)
        {
            // If Overpass API times out (e.g. 504 Gateway Timeout) or fails, return empty list 
            // instead of crashing the whole app.
            Console.WriteLine($"Overpass API Error: {ex.Message}");
            return new List<Smart_Queue.Models.ServiceProvider>();
        }

        using var doc = JsonDocument.Parse(json);
        var elements = doc.RootElement.GetProperty("elements").EnumerateArray();

        var pois = new List<Smart_Queue.Models.ServiceProvider>();

        foreach (var el in elements)
        {
            if (el.TryGetProperty("tags", out var tags) && tags.TryGetProperty("name", out var nameProp))
            {
                var name = nameProp.GetString();
                if (string.IsNullOrWhiteSpace(name)) continue;

                long id = el.GetProperty("id").GetInt64();
                
                double nodeLat = 0;
                double nodeLon = 0;
                
                if (el.TryGetProperty("lat", out var latProp) && el.TryGetProperty("lon", out var lonProp)) {
                    nodeLat = latProp.GetDouble();
                    nodeLon = lonProp.GetDouble();
                } else if (el.TryGetProperty("center", out var centerProp)) {
                    nodeLat = centerProp.GetProperty("lat").GetDouble();
                    nodeLon = centerProp.GetProperty("lon").GetDouble();
                } else {
                    continue; // Cannot determine location
                }

                string amenity = tags.TryGetProperty("amenity", out var am) ? am.GetString() ?? "" : "";
                string tourism = tags.TryGetProperty("tourism", out var tu) ? tu.GetString() ?? "" : "";

                var category = DetermineCategory(amenity, tourism);

                // Build simple address if available
                var street = tags.TryGetProperty("addr:street", out var st) ? st.GetString() : "";
                var city = tags.TryGetProperty("addr:city", out var ct) ? ct.GetString() : "";
                var suburb = tags.TryGetProperty("addr:suburb", out var su) ? su.GetString() : "";
                var state = tags.TryGetProperty("addr:state", out var sta) ? sta.GetString() : "";
                
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
                    Rating = Math.Round(3.5 + (new Random((int)id).NextDouble() * 1.5), 1) // 3.5 to 5.0, 1 decimal point
                };
                
                pois.Add(poi);
            }
        }

        // Cache for 24 hours
        _cache.Set(cacheKey, pois, TimeSpan.FromHours(24));

        return pois;
    }

    private ServiceCategory DetermineCategory(string amenity, string tourism)
    {
        return (amenity.ToLower(), tourism.ToLower()) switch
        {
            ("hospital" or "clinic", _) => ServiceCategory.Hospital,
            ("bank", _) => ServiceCategory.Bank,
            ("university" or "college", _) => ServiceCategory.College,
            ("townhall" or "courthouse", _) => ServiceCategory.GovtOffice,
            ("restaurant" or "cafe" or "fast_food", _) => ServiceCategory.Restaurant,
            (_, "hotel" or "motel") => ServiceCategory.Hotel,
            _ => ServiceCategory.Other
        };
    }
}
