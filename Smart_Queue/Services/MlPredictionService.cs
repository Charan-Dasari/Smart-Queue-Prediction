using System.Text.Json;
using System.Text;

namespace Smart_Queue.Services;

public class MlPredictionService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<MlPredictionService> _logger;

    public MlPredictionService(HttpClient httpClient, ILogger<MlPredictionService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<int> PredictWaitTimeAsync(
        int queueLength,
        string serviceType,
        string priorityLevel,
        int activeStaffCount)
    {
        try
        {
            var payload = new
            {
                features = new Dictionary<string, object>
                {
                    { "queue_length", queueLength },
                    { "hour_of_day", DateTime.Now.Hour },
                    { "active_staff_count", activeStaffCount },
                    { "service_type", serviceType.ToLower() },
                    { "priority_level", priorityLevel.ToLower() }
                }
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("/predict_wait_time", content);
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseString);
            
            if (doc.RootElement.TryGetProperty("estimated_wait_time_minutes", out var waitTimeElement))
            {
                return (int)Math.Round(waitTimeElement.GetDouble());
            }

            return CalculateFallback(queueLength);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to call ML prediction API. Using fallback logic.");
            return CalculateFallback(queueLength);
        }
    }

    private int CalculateFallback(int queueLength)
    {
        // Simple fallback if Python API is offline
        return (queueLength + 1) * 15;
    }
}
