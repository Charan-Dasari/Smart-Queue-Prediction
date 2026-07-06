using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class QueueService
{
    private readonly SmartQueueDbContext _db;

    public QueueService(SmartQueueDbContext db) => _db = db;

    /// <summary>
    /// Generate next token number for a provider (e.g., H-201, B-301)
    /// </summary>
    public async Task<string> GenerateTokenNumberAsync(Guid providerId)
    {
        var provider = await _db.ServiceProviders.FindAsync(providerId);
        var prefix = provider?.Category switch
        {
            ServiceCategory.Hospital => "H",
            ServiceCategory.Bank => "B",
            ServiceCategory.GovtOffice => "G",
            ServiceCategory.College => "C",
            _ => "Q"
        };

        var todayStart = DateTime.UtcNow.Date;
        var todayCount = await _db.QueueTokens
            .Where(t => t.ProviderId == providerId && t.CreatedAt >= todayStart)
            .CountAsync();

        return $"{prefix}-{201 + todayCount}";
    }

    /// <summary>
    /// Create a queue token when an appointment is booked
    /// </summary>
    public async Task<QueueToken> CreateTokenAsync(Guid userId, Guid providerId, Guid serviceId)
    {
        var tokenNumber = await GenerateTokenNumberAsync(providerId);

        // Calculate position (how many tokens are waiting/in-queue)
        var waitingCount = await _db.QueueTokens
            .Where(t => t.ProviderId == providerId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Upcoming))
            .CountAsync();

        var service = await _db.Services.FindAsync(serviceId);
        var estimatedWait = (waitingCount + 1) * (service?.AvgDurationMinutes ?? 15);

        var token = new QueueToken
        {
            TokenNumber = tokenNumber,
            Position = waitingCount + 1,
            EstimatedWaitMinutes = estimatedWait,
            Status = AppointmentStatus.InQueue,
            UserId = userId,
            ProviderId = providerId,
            ServiceId = serviceId,
        };

        _db.QueueTokens.Add(token);
        await _db.SaveChangesAsync();

        return token;
    }

    /// <summary>
    /// Staff calls the next person in queue to their counter
    /// </summary>
    public async Task<QueueTokenDto?> CallNextAsync(Guid staffUserId)
    {
        var counter = await _db.ServiceCounters
            .FirstOrDefaultAsync(c => c.StaffUserId == staffUserId && c.Status == CounterStatus.Active);

        if (counter == null) return null;

        // Find next waiting token for this provider
        var nextToken = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.User)
            .Where(t => t.ProviderId == counter.ProviderId && t.Status == AppointmentStatus.InQueue)
            .OrderBy(t => t.Position)
            .FirstOrDefaultAsync();

        if (nextToken == null) return null;

        // Update token
        nextToken.Status = AppointmentStatus.Serving;
        nextToken.CounterId = counter.Id;
        nextToken.ServedAt = DateTime.UtcNow;

        // Update counter
        counter.ActiveTokenId = nextToken.Id;

        // Log activity
        _db.ActivityLogs.Add(new ActivityLog
        {
            Action = $"Called {nextToken.TokenNumber} to Counter #{counter.Number}",
            ProviderId = counter.ProviderId,
            UserId = staffUserId,
        });

        // Recalculate positions for remaining tokens
        var remainingTokens = await _db.QueueTokens
            .Where(t => t.ProviderId == counter.ProviderId && t.Status == AppointmentStatus.InQueue)
            .OrderBy(t => t.Position)
            .ToListAsync();

        for (int i = 0; i < remainingTokens.Count; i++)
        {
            remainingTokens[i].Position = i + 1;
            remainingTokens[i].EstimatedWaitMinutes = (i + 1) * 8; // Rough estimate
        }

        await _db.SaveChangesAsync();

        return MapToDto(nextToken);
    }

    /// <summary>
    /// Mark current token as completed
    /// </summary>
    public async Task<bool> CompleteTokenAsync(Guid tokenId, Guid staffUserId)
    {
        var token = await _db.QueueTokens.FindAsync(tokenId);
        if (token == null || token.Status != AppointmentStatus.Serving) return false;

        token.Status = AppointmentStatus.Completed;
        token.CompletedAt = DateTime.UtcNow;

        // Update counter
        var counter = await _db.ServiceCounters
            .FirstOrDefaultAsync(c => c.ActiveTokenId == tokenId);

        if (counter != null)
        {
            counter.ActiveTokenId = null;
            counter.TodayCustomers++;
        }

        // Update related appointment
        var appointment = await _db.Appointments
            .FirstOrDefaultAsync(a => a.TokenNumber == token.TokenNumber && a.ProviderId == token.ProviderId);
        if (appointment != null)
            appointment.Status = AppointmentStatus.Completed;

        // Log activity
        _db.ActivityLogs.Add(new ActivityLog
        {
            Action = $"Completed service for {token.TokenNumber}",
            ProviderId = token.ProviderId,
            UserId = staffUserId,
        });

        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Skip absent customer
    /// </summary>
    public async Task<bool> SkipTokenAsync(Guid tokenId, Guid staffUserId)
    {
        var token = await _db.QueueTokens.FindAsync(tokenId);
        if (token == null) return false;

        token.Status = AppointmentStatus.Cancelled;
        token.CompletedAt = DateTime.UtcNow;

        // Clear counter
        var counter = await _db.ServiceCounters
            .FirstOrDefaultAsync(c => c.ActiveTokenId == tokenId);

        if (counter != null)
            counter.ActiveTokenId = null;

        // Log activity
        _db.ActivityLogs.Add(new ActivityLog
        {
            Action = $"Marked {token.TokenNumber} as Absent (Skipped)",
            ProviderId = token.ProviderId,
            UserId = staffUserId,
        });

        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Get the queue for a provider
    /// </summary>
    public async Task<List<QueueTokenDto>> GetProviderQueueAsync(Guid providerId)
    {
        var tokens = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.User)
            .Where(t => t.ProviderId == providerId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving))
            .OrderBy(t => t.Status == AppointmentStatus.Serving ? 0 : 1)
            .ThenBy(t => t.Position)
            .ToListAsync();

        return tokens.Select(MapToDto).ToList();
    }

    /// <summary>
    /// Get user's active token
    /// </summary>
    public async Task<QueueTokenDto?> GetUserActiveTokenAsync(Guid userId)
    {
        var token = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Where(t => t.UserId == userId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving))
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        return token == null ? null : MapToDto(token);
    }

    /// <summary>
    /// Get tracking info for a specific token
    /// </summary>
    public async Task<QueueTokenDto?> GetTrackingInfoAsync(Guid tokenId)
    {
        var token = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == tokenId);

        return token == null ? null : MapToDto(token);
    }

    public async Task<QueueTokenDto?> GetTrackingInfoByAppointmentIdAsync(Guid appointmentId)
    {
        var appointment = await _db.Appointments.FindAsync(appointmentId);
        if (appointment == null) return null;

        var token = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.TokenNumber == appointment.TokenNumber && t.ProviderId == appointment.ProviderId);

        return token == null ? null : MapToDto(token);
    }

    public static QueueTokenDto MapToDto(QueueToken token) => new()
    {
        Id = token.Id,
        TokenNumber = token.TokenNumber,
        ProviderName = token.Provider?.Name ?? "",
        ServiceName = token.Service?.Name ?? "",
        UserName = token.User?.Name,
        Position = token.Position,
        EstimatedWaitMinutes = token.EstimatedWaitMinutes,
        Status = token.Status,
        CounterId = token.CounterId,
        CreatedAt = token.CreatedAt,
        ServedAt = token.ServedAt,
        CompletedAt = token.CompletedAt,
    };
}
