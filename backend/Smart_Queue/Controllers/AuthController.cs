using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Smart_Queue.DTOs;
using Smart_Queue.Services;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    public AuthController(AuthService authService) => _authService = authService;

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await _authService.LoginAsync(request);
        if (result == null)
            return Unauthorized(new { message = "Invalid email or password" });

        return Ok(result);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        if (result == null)
            return Conflict(new { message = "Email already registered" });

        return Ok(result);
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = GetUserId();
        var profile = await _authService.GetProfileAsync(userId);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = GetUserId();
        var result = await _authService.UpdateProfileAsync(userId, request);
        if (result == null) return BadRequest(new { message = "Update failed. Email may already be in use." });
        return Ok(result);
    }

    [Authorize]
    [HttpPut("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = GetUserId();
        var success = await _authService.ChangePasswordAsync(userId, request);
        if (!success) return BadRequest(new { message = "Current password is incorrect" });
        return Ok(new { message = "Password changed successfully" });
    }

    [HttpPost("reset-password-verify")]
    public async Task<IActionResult> ResetPasswordVerify([FromBody] ResetPasswordVerifyRequest request)
    {
        var success = await _authService.ResetPasswordVerifyAsync(request);
        if (!success) return BadRequest(new { message = "Verification failed. Details do not match our records." });
        
        return Ok(new { message = "Password reset successfully." });
    }

    private Guid GetUserId()
    {
        var claim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        return Guid.Parse(claim!.Value);
    }
}
