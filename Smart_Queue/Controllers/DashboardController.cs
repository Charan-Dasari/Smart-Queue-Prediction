using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Smart_Queue.Services;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly DashboardService _dashboardService;

    public DashboardController(DashboardService dashboardService) => _dashboardService = dashboardService;

    [HttpGet("user")]
    public async Task<IActionResult> GetUserDashboard()
    {
        var userId = GetUserId();
        var dashboard = await _dashboardService.GetUserDashboardAsync(userId);
        return Ok(dashboard);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("admin")]
    public async Task<IActionResult> GetAdminDashboard()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest(new { message = "No provider associated" });

        var dashboard = await _dashboardService.GetAdminDashboardAsync(providerId.Value);
        return Ok(dashboard);
    }

    [Authorize(Roles = "Staff")]
    [HttpGet("staff")]
    public async Task<IActionResult> GetStaffDashboard()
    {
        var userId = GetUserId();
        var dashboard = await _dashboardService.GetStaffDashboardAsync(userId);
        return Ok(dashboard);
    }

    [Authorize(Roles = "SuperAdmin")]
    [HttpGet("super-admin")]
    public async Task<IActionResult> GetSuperAdminDashboard()
    {
        var dashboard = await _dashboardService.GetSuperAdminDashboardAsync();
        return Ok(dashboard);
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}
