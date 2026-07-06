using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.Models;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class StaffController : ControllerBase
{
    private readonly SmartQueueDbContext _db;

    public StaffController(SmartQueueDbContext db) => _db = db;

    [HttpGet("provider")]
    public async Task<IActionResult> GetProviderStaff()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var staff = await _db.Users
            .Where(u => u.ProviderId == providerId && u.Role == UserRole.Staff)
            .Select(u => new
            {
                Id = u.Id,
                Name = u.Name,
                Email = u.Email
            })
            .ToListAsync();

        return Ok(staff);
    }

    [HttpPost]
    public async Task<IActionResult> CreateStaff([FromBody] CreateStaffRequest request)
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var provider = await _db.Places.FindAsync(providerId);
        if (provider == null) return NotFound();

        var sanitizedFirstName = request.FirstName.Trim().ToLower().Replace(" ", "");
        var sanitizedLastName = request.LastName.Trim().ToLower().Replace(" ", "");
        var sanitizedProviderName = provider.Name.ToLower().Replace(" ", "").Replace("-", "");

        var email = $"{sanitizedFirstName}.{sanitizedLastName}@{sanitizedProviderName}.com";
        var password = $"{sanitizedFirstName}@123";

        // Check if user already exists
        if (await _db.Users.AnyAsync(u => u.Email == email))
        {
            return BadRequest(new { message = "A staff member with this name combination already exists." });
        }

        var newStaff = new User
        {
            Name = $"{request.FirstName.Trim()} {request.LastName.Trim()}",
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = UserRole.Staff,
            ProviderId = providerId.Value
        };

        _db.Users.Add(newStaff);
        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Staff created successfully",
            email = email,
            password = password,
            name = newStaff.Name
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteStaff(Guid id)
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var staff = await _db.Users.FirstOrDefaultAsync(u => u.Id == id && u.ProviderId == providerId && u.Role == UserRole.Staff);
        if (staff == null) return NotFound();

        // Check if assigned to any counters and unassign
        var counters = await _db.ServiceCounters.Where(c => c.StaffUserId == id).ToListAsync();
        foreach (var c in counters)
        {
            c.StaffUserId = null;
            c.Status = CounterStatus.Offline;
        }

        _db.Users.Remove(staff);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Staff removed successfully" });
    }

    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}

public class CreateStaffRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}
