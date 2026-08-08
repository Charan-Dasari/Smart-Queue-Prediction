using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Smart_Queue.Services;
using System.Security.Claims;

using Smart_Queue.Data;
using Smart_Queue.Models;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QueueController : ControllerBase
{
    private readonly QueueService _queueService;
    private readonly SmartQueueDbContext _db;

    public QueueController(QueueService queueService, SmartQueueDbContext db)
    {
        _queueService = queueService;
        _db = db;
    }

    [Authorize(Roles = "Staff,Admin")]
    [HttpGet("provider")]
    public async Task<IActionResult> GetProviderQueue()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest(new { message = "No provider associated" });

        var queue = await _queueService.GetProviderQueueAsync(providerId.Value);
        return Ok(queue);
    }

    [HttpPost("join")]
    public async Task<IActionResult> JoinQueue([FromBody] Smart_Queue.DTOs.JoinQueueRequest request)
    {
        var userId = GetUserId();
        
        var token = await _queueService.CreateTokenAsync(userId, request.ProviderId, request.ServiceId);

        var istZone = TimeZoneInfo.FindSystemTimeZoneById("India Standard Time");
        var localNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, istZone);

        // Also create a "virtual" appointment for history
        var appointment = new Appointment
        {
            TokenNumber = token.TokenNumber,
            Date = localNow,
            Status = AppointmentStatus.InQueue,
            UserId = userId,
            ProviderId = request.ProviderId,
            ServiceId = request.ServiceId
        };
        _db.Appointments.Add(appointment);
        await _db.SaveChangesAsync();
        
        return Ok(token);
    }

    [HttpGet("my-token")]
    public async Task<IActionResult> GetMyToken()
    {
        var userId = GetUserId();
        var token = await _queueService.GetUserActiveTokenAsync(userId);
        if (token == null) return Ok(new { message = "No active token" });
        return Ok(token);
    }

    [HttpGet("my-tokens")]
    public async Task<IActionResult> GetMyTokens()
    {
        var userId = GetUserId();
        var tokens = await _queueService.GetUserActiveTokensAsync(userId);
        return Ok(tokens);
    }

    [Authorize(Roles = "Staff")]
    [HttpPost("call-next")]
    public async Task<IActionResult> CallNext()
    {
        var userId = GetUserId();
        var token = await _queueService.CallNextAsync(userId);
        if (token == null) return Ok(new { message = "No customers waiting in the queue" });
        return Ok(token);
    }

    [Authorize(Roles = "Staff")]
    [HttpPut("{tokenId}/complete")]
    public async Task<IActionResult> Complete(Guid tokenId)
    {
        var userId = GetUserId();
        var success = await _queueService.CompleteTokenAsync(tokenId, userId);
        if (!success) return BadRequest(new { message = "Cannot complete this token" });
        return Ok(new { message = "Service marked as completed" });
    }

    [Authorize(Roles = "Staff")]
    [HttpPut("{tokenId}/skip")]
    public async Task<IActionResult> Skip(Guid tokenId, [FromBody] Smart_Queue.DTOs.SkipTokenRequest request)
    {
        var userId = GetUserId();
        var success = await _queueService.SkipTokenAsync(tokenId, userId, request.Reason);
        if (!success) return BadRequest(new { message = "Cannot skip this token" });
        return Ok(new { message = "Token skipped", reason = request.Reason });
    }

    [HttpGet("tracking/{tokenId}")]
    public async Task<IActionResult> GetTracking(Guid tokenId)
    {
        var token = await _queueService.GetTrackingInfoAsync(tokenId);
        if (token == null)
        {
            token = await _queueService.GetTrackingInfoByAppointmentIdAsync(tokenId);
        }
        if (token == null) return NotFound();
        return Ok(token);
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}
