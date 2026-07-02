using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api")]
public class ServicesController : ControllerBase
{
    private readonly SmartQueueDbContext _db;

    public ServicesController(SmartQueueDbContext db) => _db = db;

    [HttpGet("providers/{providerId}/services")]
    public async Task<IActionResult> GetByProvider(Guid providerId)
    {
        var services = await _db.Services
            .Where(s => s.ProviderId == providerId)
            .Select(s => new ServiceDto
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                AvgDurationMinutes = s.AvgDurationMinutes,
                Cost = s.Cost,
                IsActive = s.IsActive,
                ProviderId = s.ProviderId,
            })
            .ToListAsync();

        return Ok(services);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("providers/{providerId}/services")]
    public async Task<IActionResult> Create(Guid providerId, [FromBody] CreateServiceRequest request)
    {
        var provider = await _db.ServiceProviders.FindAsync(providerId);
        if (provider == null) return NotFound(new { message = "Provider not found" });

        var service = new Service
        {
            Name = request.Name,
            Description = request.Description,
            AvgDurationMinutes = request.AvgDurationMinutes,
            Cost = request.Cost,
            IsActive = request.IsActive,
            ProviderId = providerId,
        };

        _db.Services.Add(service);
        await _db.SaveChangesAsync();

        return Ok(new ServiceDto
        {
            Id = service.Id,
            Name = service.Name,
            Description = service.Description,
            AvgDurationMinutes = service.AvgDurationMinutes,
            Cost = service.Cost,
            IsActive = service.IsActive,
            ProviderId = service.ProviderId,
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("services/{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateServiceRequest request)
    {
        var service = await _db.Services.FindAsync(id);
        if (service == null) return NotFound();

        if (request.Name != null) service.Name = request.Name;
        if (request.Description != null) service.Description = request.Description;
        if (request.AvgDurationMinutes.HasValue) service.AvgDurationMinutes = request.AvgDurationMinutes.Value;
        if (request.Cost.HasValue) service.Cost = request.Cost.Value;
        if (request.IsActive.HasValue) service.IsActive = request.IsActive.Value;

        await _db.SaveChangesAsync();

        return Ok(new ServiceDto
        {
            Id = service.Id,
            Name = service.Name,
            Description = service.Description,
            AvgDurationMinutes = service.AvgDurationMinutes,
            Cost = service.Cost,
            IsActive = service.IsActive,
            ProviderId = service.ProviderId,
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("services/{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var service = await _db.Services.FindAsync(id);
        if (service == null) return NotFound();

        _db.Services.Remove(service);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Service deleted" });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("services/{id}/toggle")]
    public async Task<IActionResult> Toggle(Guid id)
    {
        var service = await _db.Services.FindAsync(id);
        if (service == null) return NotFound();

        service.IsActive = !service.IsActive;
        await _db.SaveChangesAsync();

        return Ok(new { isActive = service.IsActive });
    }

    // ── Time Slots ──
    [HttpGet("services/{serviceId}/timeslots")]
    public async Task<IActionResult> GetTimeSlots(Guid serviceId, [FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;

        var slots = await _db.TimeSlots
            .Where(t => t.ServiceId == serviceId && t.StartTime.Date == targetDate)
            .OrderBy(t => t.StartTime)
            .Select(t => new TimeSlotDto
            {
                Id = t.Id,
                StartTime = t.StartTime,
                EndTime = t.EndTime,
                TotalSlots = t.TotalSlots,
                AvailableSlots = t.AvailableSlots,
                CrowdLevel = t.CrowdLevel,
                AiScore = t.AiScore,
            })
            .ToListAsync();

        return Ok(slots);
    }
}
