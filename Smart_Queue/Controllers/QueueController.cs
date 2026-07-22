using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Smart_Queue.Services;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QueueController : ControllerBase
{
    private readonly QueueService _queueService;

    public QueueController(QueueService queueService) => _queueService = queueService;

    [Authorize(Roles = "Staff,Admin")]
    [HttpGet("provider")]
    public async Task<IActionResult> GetProviderQueue()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest(new { message = "No provider associated" });

        var queue = await _queueService.GetProviderQueueAsync(providerId.Value);
        return Ok(queue);
    }

    [HttpGet("my-token")]
    public async Task<IActionResult> GetMyToken()
    {
        var userId = GetUserId();
        var token = await _queueService.GetUserActiveTokenAsync(userId);
        if (token == null) return Ok(new { message = "No active token" });
        return Ok(token);
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
    public async Task<IActionResult> Skip(Guid tokenId)
    {
        var userId = GetUserId();
        var success = await _queueService.SkipTokenAsync(tokenId, userId);
        if (!success) return BadRequest(new { message = "Cannot skip this token" });
        return Ok(new { message = "Token skipped and marked absent" });
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
