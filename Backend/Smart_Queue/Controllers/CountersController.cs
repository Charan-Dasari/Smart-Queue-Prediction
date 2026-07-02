using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using System.Security.Claims;

namespace Smart_Queue.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class CountersController : ControllerBase
{
    private readonly SmartQueueDbContext _db;

    public CountersController(SmartQueueDbContext db) => _db = db;

    [HttpGet("provider")]
    public async Task<IActionResult> GetProviderCounters()
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var counters = await _db.ServiceCounters
            .Include(c => c.StaffUser)
            .Include(c => c.ActiveToken)
            .Where(c => c.ProviderId == providerId)
            .OrderBy(c => c.Number)
            .Select(c => new CounterDto
            {
                Id = c.Id,
                Number = c.Number,
                ServiceName = c.ServiceName,
                Status = c.Status,
                StaffName = c.StaffUser != null ? c.StaffUser.Name : "Unassigned",
                StaffUserId = c.StaffUserId,
                ActiveTokenNumber = c.ActiveToken != null ? c.ActiveToken.TokenNumber : null,
                TodayCustomers = c.TodayCustomers,
                AvgServiceMinutes = c.AvgServiceMinutes,
            })
            .ToListAsync();

        return Ok(counters);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCounterRequest request)
    {
        var providerId = GetProviderId();
        if (providerId == null) return BadRequest();

        var counter = new ServiceCounter
        {
            Number = request.Number,
            ServiceName = request.ServiceName,
            ProviderId = providerId.Value,
            Status = CounterStatus.Offline,
        };

        _db.ServiceCounters.Add(counter);
        await _db.SaveChangesAsync();

        return Ok(new CounterDto
        {
            Id = counter.Id,
            Number = counter.Number,
            ServiceName = counter.ServiceName,
            Status = counter.Status,
            StaffName = "Unassigned",
        });
    }

    [HttpPut("{id}/assign")]
    public async Task<IActionResult> Assign(Guid id, [FromBody] AssignCounterRequest request)
    {
        var counter = await _db.ServiceCounters.FindAsync(id);
        if (counter == null) return NotFound();

        if (request.StaffUserId.HasValue)
        {
            counter.StaffUserId = request.StaffUserId;
            counter.Status = CounterStatus.Active;
        }
        else
        {
            counter.StaffUserId = null;
            counter.Status = CounterStatus.Offline;
        }

        if (request.ServiceName != null)
            counter.ServiceName = request.ServiceName;

        await _db.SaveChangesAsync();
        return Ok(new { message = "Counter updated" });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateCounterStatusRequest request)
    {
        var counter = await _db.ServiceCounters.FindAsync(id);
        if (counter == null) return NotFound();

        counter.Status = request.Status;
        await _db.SaveChangesAsync();

        return Ok(new { status = counter.Status.ToString() });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var counter = await _db.ServiceCounters.FindAsync(id);
        if (counter == null) return NotFound();

        _db.ServiceCounters.Remove(counter);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Counter removed" });
    }

    private Guid? GetProviderId()
    {
        var claim = User.FindFirst("ProviderId");
        return claim != null && Guid.TryParse(claim.Value, out var id) ? id : null;
    }
}
