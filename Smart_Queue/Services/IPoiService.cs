using Smart_Queue.Models;

namespace Smart_Queue.Services;

public interface IPoiService
{
    Task<List<Smart_Queue.Models.ServiceProvider>> GetNearbyPoisAsync(double lat, double lon, double radiusMeters = 5000);
}
