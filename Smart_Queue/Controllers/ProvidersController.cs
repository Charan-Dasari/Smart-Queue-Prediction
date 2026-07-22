using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using Smart_Queue.Services;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProvidersController : ControllerBase
{
    private readonly ProviderService _providerService;
    private readonly SmartQueueDbContext _db;

    public ProvidersController(ProviderService providerService, SmartQueueDbContext db)
    {
        _providerService = providerService;
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? category, [FromQuery] string? q)
    {
        var providers = await _providerService.GetAllProvidersAsync(category, q);
        return Ok(providers);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProvider(Guid id)
    {
        var provider = await _providerService.GetProviderWithServicesAsync(id);
        if (provider == null) return NotFound();
        return Ok(provider);
    }

    [HttpGet("{id}/counters")]
    public async Task<IActionResult> GetProviderCounters(Guid id)
    {
        var counters = await _db.ServiceCounters
            .Where(c => c.ProviderId == id)
            .ToListAsync();

        return Ok(counters.Select(c => new CounterDto
        {
            Id = c.Id,
            Number = c.Number,
            Status = c.Status,
            ServiceName = c.ServiceName
        }));
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
