using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using Smart_Queue.Services;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly SmartQueueDbContext _db;
    private readonly QueueService _queueService;
    private readonly NotificationService _notificationService;

    public AppointmentsController(SmartQueueDbContext db, QueueService queueService, NotificationService notificationService)
    {
        _db = db;
        _queueService = queueService;
        _notificationService = notificationService;
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyAppointments()
    {
        var userId = GetUserId();
        var appointments = await _db.Appointments
            .Include(a => a.Provider)
            .Include(a => a.Service)
            .Include(a => a.TimeSlot)
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.Date)
            .Select(a => new AppointmentDto
            {
                Id = a.Id,
                TokenNumber = a.TokenNumber,
                ProviderName = a.Provider.Name,
                ServiceName = a.Service.Name,
                Date = a.Date,
                Status = a.Status,
                ProviderId = a.ProviderId,
                ServiceId = a.ServiceId,
                TimeSlot = a.TimeSlot != null ? new TimeSlotDto
                {
                    Id = a.TimeSlot.Id,
                    StartTime = a.TimeSlot.StartTime,
                    EndTime = a.TimeSlot.EndTime,
                    TotalSlots = a.TimeSlot.TotalSlots,
                    AvailableSlots = a.TimeSlot.AvailableSlots,
                    CrowdLevel = a.TimeSlot.CrowdLevel,
                    AiScore = a.TimeSlot.AiScore,
                } : null,
                CreatedAt = a.CreatedAt,
            })
            .ToListAsync();

        return Ok(appointments);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("provider")]
    public async Task<IActionResult> GetProviderAppointments()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest(new { message = "No provider associated" });

        var appointments = await _db.Appointments
            .Include(a => a.Provider)
            .Include(a => a.Service)
            .Include(a => a.User)
            .Where(a => a.ProviderId == providerId)
            .OrderByDescending(a => a.Date)
            .Select(a => new AppointmentDto
            {
                Id = a.Id,
                TokenNumber = a.TokenNumber,
                ProviderName = a.Provider.Name,
                ServiceName = a.Service.Name,
                Date = a.Date,
                Status = a.Status,
                ProviderId = a.ProviderId,
                ServiceId = a.ServiceId,
                CreatedAt = a.CreatedAt,
            })
            .ToListAsync();

        return Ok(appointments);
    }

    [HttpPost]
    public async Task<IActionResult> Book([FromBody] BookAppointmentRequest request)
    {
        var userId = GetUserId();

        // Validate time slot
        TimeSlot? timeSlot = null;
        if (request.TimeSlotId.HasValue)
        {
            timeSlot = await _db.TimeSlots.FindAsync(request.TimeSlotId.Value);
            if (timeSlot == null || timeSlot.AvailableSlots <= 0)
                return BadRequest(new { message = "Selected time slot is not available" });
        }

        // Create queue token
        var queueToken = await _queueService.CreateTokenAsync(userId, request.ProviderId, request.ServiceId);

        // Create appointment
        var appointment = new Appointment
        {
            TokenNumber = queueToken.TokenNumber,
            Date = request.Date,
            Status = AppointmentStatus.Upcoming,
            UserId = userId,
            ProviderId = request.ProviderId,
            ServiceId = request.ServiceId,
            TimeSlotId = request.TimeSlotId,
        };

        _db.Appointments.Add(appointment);

        // Decrease available slots
        if (timeSlot != null)
        {
            timeSlot.AvailableSlots--;
        }

        await _db.SaveChangesAsync();

        // Send notification
        var provider = await _db.ServiceProviders.FindAsync(request.ProviderId);
        var service = await _db.Services.FindAsync(request.ServiceId);
        await _notificationService.CreateBookingNotificationAsync(
            userId, provider?.Name ?? "", service?.Name ?? "", queueToken.TokenNumber);

        return Ok(new AppointmentDto
        {
            Id = appointment.Id,
            TokenNumber = appointment.TokenNumber,
            ProviderName = provider?.Name ?? "",
            ServiceName = service?.Name ?? "",
            Date = appointment.Date,
            Status = appointment.Status,
            ProviderId = appointment.ProviderId,
            ServiceId = appointment.ServiceId,
            CreatedAt = appointment.CreatedAt,
        });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var appointment = await _db.Appointments
            .Include(a => a.Provider)
            .Include(a => a.Service)
            .Include(a => a.TimeSlot)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (appointment == null) return NotFound();

        return Ok(new AppointmentDto
        {
            Id = appointment.Id,
            TokenNumber = appointment.TokenNumber,
            ProviderName = appointment.Provider?.Name ?? "",
            ServiceName = appointment.Service?.Name ?? "",
            Date = appointment.Date,
            Status = appointment.Status,
            ProviderId = appointment.ProviderId,
            ServiceId = appointment.ServiceId,
            TimeSlot = appointment.TimeSlot != null ? new TimeSlotDto
            {
                Id = appointment.TimeSlot.Id,
                StartTime = appointment.TimeSlot.StartTime,
                EndTime = appointment.TimeSlot.EndTime,
            } : null,
            CreatedAt = appointment.CreatedAt,
        });
    }

    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> Cancel(Guid id)
    {
        var appointment = await _db.Appointments.FindAsync(id);
        if (appointment == null) return NotFound();

        appointment.Status = AppointmentStatus.Cancelled;

        // Also cancel the queue token
        var token = await _db.QueueTokens
            .FirstOrDefaultAsync(t => t.TokenNumber == appointment.TokenNumber && t.ProviderId == appointment.ProviderId);
        if (token != null)
            token.Status = AppointmentStatus.Cancelled;

        // Restore time slot
        if (appointment.TimeSlotId.HasValue)
        {
            var slot = await _db.TimeSlots.FindAsync(appointment.TimeSlotId);
            if (slot != null) slot.AvailableSlots++;
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Appointment cancelled" });
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}
