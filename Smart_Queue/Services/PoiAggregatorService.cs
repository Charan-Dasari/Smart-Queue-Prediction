using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class PoiAggregatorService : IPoiService
{
    private readonly List<IPoiService> _poiServices;

    public PoiAggregatorService(GeoapifyService geoapifyService, OsmService osmService)
    {
        // Order matters! Geoapify is primary, OSM is fallback/merged.
        _poiServices = new List<IPoiService> { geoapifyService, osmService };
    }

    public async Task<List<Smart_Queue.Models.ServiceProvider>> GetNearbyPoisAsync(double lat, double lon, double radiusMeters = 5000)
    {
        var allPois = new List<Smart_Queue.Models.ServiceProvider>();

        // We run them concurrently to merge results quickly
        var tasks = _poiServices.Select(service => service.GetNearbyPoisAsync(lat, lon, radiusMeters));
        var results = await Task.WhenAll(tasks);

        foreach (var result in results)
        {
            if (result != null)
            {
                allPois.AddRange(result);
            }
        }

        // Deduplicate by Name and Category to avoid showing the same hospital twice
        var uniquePois = allPois
            .GroupBy(p => new { p.Name, p.Category })
            .Select(g => g.First())
            .ToList();

        return uniquePois;
    }
}
