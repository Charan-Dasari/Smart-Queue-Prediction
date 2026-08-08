using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using Smart_Queue.Services;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProvidersController : ControllerBase
{
    private readonly ProviderService _providerService;
    private readonly SmartQueueDbContext _db;
    private readonly MlPredictionService _mlPredictionService;

    public ProvidersController(ProviderService providerService, SmartQueueDbContext db, MlPredictionService mlPredictionService)
    {
        _providerService = providerService;
        _db = db;
        _mlPredictionService = mlPredictionService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? category, [FromQuery] string? q)
    {
        var providers = await _providerService.GetAllProvidersAsync(category, q);
        return Ok(providers);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProvider(Guid id)
    {
        var provider = await _providerService.GetProviderWithServicesAsync(id);
        if (provider == null) return NotFound();
        return Ok(provider);
    }

    [HttpGet("{id}/counters")]
    public async Task<IActionResult> GetProviderCounters(Guid id)
    {
        // Only return counters that have staff assigned (user-facing endpoint)
        var counters = await _db.ServiceCounters
            .Where(c => c.ProviderId == id)
            .Where(c => c.StaffUserId != null)
            .ToListAsync();

        return Ok(counters.Select(c => new CounterDto
        {
            Id = c.Id,
            Number = c.Number,
            Status = c.Status,
            ServiceName = c.ServiceName
        }));
    }

    [HttpGet("{id}/services/{serviceId}/timeslots")]
    public async Task<IActionResult> GetTimeSlots(Guid id, Guid serviceId, [FromQuery] string date)
    {
        if (!DateTime.TryParse(date, out DateTime requestedDate))
        {
            return BadRequest("Invalid date format.");
        }

        var provider = await _db.ServiceProviders.FindAsync(id);
        var service = await _db.Services.FindAsync(serviceId);

        if (provider == null || service == null)
            return NotFound("Provider or Service not found.");

        var timeSlots = new List<TimeSlotResponseDto>();
        
        // Define operating hours (e.g., 9 AM to 6 PM)
        int startHour = provider.Category == ServiceCategory.Restaurant ? 11 : 9;
        int endHour = provider.Category == ServiceCategory.Restaurant ? 22 : 18;
        
        // Use India Standard Time (IST)
        var istZone = TimeZoneInfo.FindSystemTimeZoneById("India Standard Time");
        var now = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, istZone);
        
        // Get all appointments for this provider, service, and specific date
        var appointmentsForDate = await _db.Appointments
            .Where(a => a.ProviderId == id && a.ServiceId == serviceId && a.Date.Date == requestedDate.Date)
            .ToListAsync();

        int maxCapacityPerSlot = 5; // e.g. 5 appointments max per 30-min slot
        int activeStaffCount = 3; // Mock active staff
        string priorityLevel = "standard";

        // First pass: Collect slot data without ML predictions
        var slotInfos = new List<(int hour, int min, int bookedCount, bool isFull)>();

        for (int hour = startHour; hour <= endHour; hour++)
        {
            foreach (int min in new[] { 0, 30 })
            {
                if (hour == endHour && min > 0) continue;

                if (requestedDate.Date == now.Date)
                {
                    if (hour < now.Hour || (hour == now.Hour && min <= now.Minute))
                    {
                        continue;
                    }
                }

                int bookedCount = appointmentsForDate.Count(a => a.Date.Hour == hour && a.Date.Minute == min);
                bool isFull = bookedCount >= maxCapacityPerSlot;
                slotInfos.Add((hour, min, bookedCount, isFull));
            }
        }

        // Second pass: Fire ALL ML predictions in parallel (massive speedup!)
        var mlTasks = slotInfos.Select(s =>
            _mlPredictionService.PredictWaitTimeAsync(
                queueLength: s.bookedCount,
                serviceType: service.Name,
                priorityLevel: priorityLevel,
                activeStaffCount: activeStaffCount,
                hourOfDay: s.hour
            )
        ).ToArray();

        int[] predictions;
        try
        {
            predictions = await Task.WhenAll(mlTasks);
        }
        catch
        {
            // If ML API is completely down, use fallback for all slots
            predictions = slotInfos.Select(s => (s.bookedCount + 1) * 15).ToArray();
        }

        // Build response
        for (int i = 0; i < slotInfos.Count; i++)
        {
            var (hour, min, bookedCount, isFull) = slotInfos[i];
            int predictedWaitMins = predictions[i];
            double crowdLevel = Math.Clamp(predictedWaitMins / 45.0, 0.0, 1.0);

            string ampm = hour >= 12 ? "PM" : "AM";
            int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            string timeStr = $"{displayHour:D2}:{min:D2} {ampm}";

            timeSlots.Add(new TimeSlotResponseDto
            {
                Time = timeStr,
                Available = !isFull,
                WaitTime = predictedWaitMins,
                CrowdLevel = crowdLevel
            });
        }

        return Ok(timeSlots);
    }

    [Authorize(Roles = "SuperAdmin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateProviderRequest request)
    {
        var (provider, adminEmail, adminPassword) = await _providerService.CreateProviderAsync(request);
        return Ok(new
        {
            provider,
            credentials = new { email = adminEmail, password = adminPassword }
        });
    }

    [Authorize(Roles = "SuperAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var success = await _providerService.DeleteProviderAsync(id);
        if (!success) return NotFound();
        return Ok(new { message = "Provider deleted successfully" });
    }
}
