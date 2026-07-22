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
[Authorize(Roles = "Admin")]
public class RolesController : ControllerBase
{
    private readonly SmartQueueDbContext _db;

    public RolesController(SmartQueueDbContext db) => _db = db;

    [HttpGet("users")]
    public async Task<IActionResult> GetProviderUsers()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var users = await _db.Users
            .Where(u => u.ProviderId == providerId)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Name = u.Name,
                Email = u.Email,
                Mobile = u.Mobile,
                Role = u.Role,
                ProviderId = u.ProviderId,
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpPut("{userId}")]
    public async Task<IActionResult> UpdateRole(Guid userId, [FromBody] UpdateRoleRequest request)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        // Only allow Admin and Staff roles for provider users
        if (request.Role != UserRole.Admin && request.Role != UserRole.Staff)
            return BadRequest(new { message = "Can only assign Admin or Staff roles" });

        user.Role = request.Role;
        await _db.SaveChangesAsync();

        return Ok(new { message = $"Role updated to {request.Role}" });
    }

    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}
