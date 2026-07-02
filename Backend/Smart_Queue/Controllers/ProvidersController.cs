using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Smart_Queue.DTOs;
using Smart_Queue.Services;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProvidersController : ControllerBase
{
    private readonly ProviderService _providerService;

    public ProvidersController(ProviderService providerService) => _providerService = providerService;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? category, [FromQuery] string? q)
    {
        var providers = await _providerService.GetAllProvidersAsync(category, q);
        return Ok(providers);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var provider = await _providerService.GetProviderWithServicesAsync(id);
        if (provider == null) return NotFound();
        return Ok(provider);
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
