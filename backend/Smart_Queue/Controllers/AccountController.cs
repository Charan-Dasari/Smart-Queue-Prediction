using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.Models;
using Smart_Queue.Services;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AccountController : ControllerBase
{
    private readonly SmartQueueDbContext _db;
    private readonly NotificationService _notificationService;

    public AccountController(SmartQueueDbContext db, NotificationService notificationService)
    {
        _db = db;
        _notificationService = notificationService;
    }

    /// <summary>
    /// SuperAdmin: Get all registered users with deletion status
    /// </summary>
    [Authorize(Roles = "SuperAdmin")]
    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = await _db.Users
            .Where(u => u.Role != UserRole.SuperAdmin)
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new
            {
                u.Id,
                u.Name,
                u.Email,
                u.Mobile,
                Role = u.Role.ToString(),
                u.CreatedAt,
                DeletionRequest = _db.AccountDeletionRequests
                    .Where(d => d.UserId == u.Id && (d.Status == DeletionStatus.Pending || d.Status == DeletionStatus.Approved))
                    .Select(d => new
                    {
                        d.Id,
                        Status = d.Status.ToString(),
                        d.RequestedAt,
                        d.ScheduledDeletionDate,
                        d.ApprovedAt,
                        d.Reason
                    })
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(users);
    }

    /// <summary>
    /// SuperAdmin: Instantly delete a user account
    /// </summary>
    [Authorize(Roles = "SuperAdmin")]
    [HttpDelete("{userId}")]
    public async Task<IActionResult> DeleteUser(Guid userId)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound(new { message = "User not found" });
        if (user.Role == UserRole.SuperAdmin) return BadRequest(new { message = "Cannot delete a Super Admin account" });

        // Remove related deletion requests
        var deletionRequests = await _db.AccountDeletionRequests.Where(d => d.UserId == userId).ToListAsync();
        _db.AccountDeletionRequests.RemoveRange(deletionRequests);

        // Remove notifications
        var notifications = await _db.Notifications.Where(n => n.UserId == userId).ToListAsync();
        _db.Notifications.RemoveRange(notifications);

        // Cancel active appointments
        var appointments = await _db.Appointments.Where(a => a.UserId == userId).ToListAsync();
        foreach (var apt in appointments) apt.Status = AppointmentStatus.Cancelled;

        // Remove queue tokens
        var tokens = await _db.QueueTokens.Where(q => q.UserId == userId).ToListAsync();
        _db.QueueTokens.RemoveRange(tokens);

        _db.Users.Remove(user);
        await _db.SaveChangesAsync();

        return Ok(new { message = "User account deleted successfully" });
    }

    /// <summary>
    /// SuperAdmin: Approve a deletion request with a timer (days)
    /// </summary>
    [Authorize(Roles = "SuperAdmin")]
    [HttpPut("approve-deletion/{userId}")]
    public async Task<IActionResult> ApproveDeletion(Guid userId, [FromQuery] int days = 3)
    {
        if (days < 1 || days > 30) return BadRequest(new { message = "Days must be between 1 and 30" });

        var request = await _db.AccountDeletionRequests
            .Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId && d.Status == DeletionStatus.Pending);

        if (request == null) return NotFound(new { message = "No pending deletion request found for this user" });

        request.Status = DeletionStatus.Approved;
        request.ApprovedAt = DateTime.UtcNow;
        request.ScheduledDeletionDate = DateTime.UtcNow.AddDays(days);

        await _db.SaveChangesAsync();

        // Notify the user
        await _notificationService.CreateAsync(
            userId,
            "Account Deletion Approved",
            $"Your account deletion request has been approved. Your account will be permanently deleted in {days} day(s). You can revoke this from your Profile if you change your mind.",
            NotificationType.System
        );

        return Ok(new { message = $"Deletion approved. Account will be deleted in {days} day(s).", scheduledDate = request.ScheduledDeletionDate });
    }

    /// <summary>
    /// User: Request account deletion
    /// </summary>
    [HttpPost("request-deletion")]
    public async Task<IActionResult> RequestDeletion([FromBody] DeletionRequestDto? dto)
    {
        var userId = GetUserId();

        // Check if there's already a pending/approved request
        var existing = await _db.AccountDeletionRequests
            .FirstOrDefaultAsync(d => d.UserId == userId && (d.Status == DeletionStatus.Pending || d.Status == DeletionStatus.Approved));

        if (existing != null) return BadRequest(new { message = "You already have an active deletion request" });

        var request = new AccountDeletionRequest
        {
            UserId = userId,
            Reason = dto?.Reason,
            Status = DeletionStatus.Pending,
            RequestedAt = DateTime.UtcNow
        };

        _db.AccountDeletionRequests.Add(request);
        await _db.SaveChangesAsync();

        // Notify all super admins
        var user = await _db.Users.FindAsync(userId);
        var superAdmins = await _db.Users.Where(u => u.Role == UserRole.SuperAdmin).ToListAsync();
        foreach (var admin in superAdmins)
        {
            await _notificationService.CreateAsync(
                admin.Id,
                "Account Deletion Request",
                $"{user?.Name} ({user?.Email}) has requested to delete their account.{(dto?.Reason != null ? $" Reason: {dto.Reason}" : "")}",
                NotificationType.System
            );
        }

        return Ok(new { message = "Your account deletion request has been submitted. A Super Admin will review it shortly." });
    }

    /// <summary>
    /// User: Revoke their pending/approved deletion request
    /// </summary>
    [HttpPost("revoke-deletion")]
    public async Task<IActionResult> RevokeDeletion()
    {
        var userId = GetUserId();

        var request = await _db.AccountDeletionRequests
            .Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId && (d.Status == DeletionStatus.Pending || d.Status == DeletionStatus.Approved));

        if (request == null) return NotFound(new { message = "No active deletion request found" });

        request.Status = DeletionStatus.Revoked;
        request.ScheduledDeletionDate = null;
        await _db.SaveChangesAsync();

        // Notify all super admins
        var superAdmins = await _db.Users.Where(u => u.Role == UserRole.SuperAdmin).ToListAsync();
        foreach (var admin in superAdmins)
        {
            await _notificationService.CreateAsync(
                admin.Id,
                "Deletion Request Revoked",
                $"{request.User.Name} ({request.User.Email}) has revoked their account deletion request.",
                NotificationType.System
            );
        }

        return Ok(new { message = "Your account deletion request has been revoked. Your account is safe." });
    }

    /// <summary>
    /// User: Get their current deletion request status
    /// </summary>
    [HttpGet("deletion-status")]
    public async Task<IActionResult> GetDeletionStatus()
    {
        var userId = GetUserId();

        var request = await _db.AccountDeletionRequests
            .Where(d => d.UserId == userId && (d.Status == DeletionStatus.Pending || d.Status == DeletionStatus.Approved))
            .Select(d => new
            {
                d.Id,
                Status = d.Status.ToString(),
                d.RequestedAt,
                d.ScheduledDeletionDate,
                d.ApprovedAt,
                d.Reason
            })
            .FirstOrDefaultAsync();

        if (request == null) return Ok(new { hasPendingRequest = false });

        return Ok(new { hasPendingRequest = true, request });
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
}

public class DeletionRequestDto
{
    public string? Reason { get; set; }
}
