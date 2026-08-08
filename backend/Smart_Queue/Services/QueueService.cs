using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class QueueService
{
    private readonly SmartQueueDbContext _db;
    private readonly MlPredictionService _mlService;

    public QueueService(SmartQueueDbContext db, MlPredictionService mlService)
    {
        _db = db;
        _mlService = mlService;
    }

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

        // Calculate position (how many tokens are waiting/in-queue) for this specific service
        var waitingCount = await _db.QueueTokens
            .Where(t => t.ProviderId == providerId && t.ServiceId == serviceId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Upcoming))
            .CountAsync();

        var service = await _db.Services.FindAsync(serviceId);
        
        // ML Model Prediction
        var activeStaff = await _db.ServiceCounters.CountAsync(c => c.ProviderId == providerId && c.Status == CounterStatus.Active);
        var estimatedWait = await _mlService.PredictWaitTimeAsync(
            queueLength: waitingCount + 1,
            serviceType: service?.Name ?? "general",
            priorityLevel: "normal",
            activeStaffCount: activeStaff > 0 ? activeStaff : 1
        );

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

        // Find next waiting token for this provider, optionally filtered by counter's service
        var nextTokenQuery = _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.User)
            .Where(t => t.ProviderId == counter.ProviderId && t.Status == AppointmentStatus.InQueue);

        if (!string.IsNullOrEmpty(counter.ServiceName) && counter.ServiceName.ToLower() != "general")
        {
            nextTokenQuery = nextTokenQuery.Where(t => t.Service.Name.ToLower() == counter.ServiceName.ToLower());
        }

        var nextToken = await nextTokenQuery
            .OrderBy(t => t.Position)
            .FirstOrDefaultAsync();

        if (nextToken == null) return null;

        // Update token
        nextToken.Status = AppointmentStatus.Serving;
        nextToken.CounterId = counter.Id;
        nextToken.ServedAt = DateTime.UtcNow;

        // Update counter
        counter.ActiveTokenId = nextToken.Id;

        // Update related appointment
        var appointment = await _db.Appointments
            .Where(a => a.TokenNumber == nextToken.TokenNumber && a.ProviderId == nextToken.ProviderId)
            .OrderByDescending(a => a.CreatedAt)
            .FirstOrDefaultAsync();
        if (appointment != null)
            appointment.Status = AppointmentStatus.Serving;

        // Log activity
        _db.ActivityLogs.Add(new ActivityLog
        {
            Action = $"Called {nextToken.TokenNumber} to Counter #{counter.Number}",
            ProviderId = counter.ProviderId,
            UserId = staffUserId,
        });

        // Recalculate positions for remaining tokens in the same service queue
        var remainingTokens = await _db.QueueTokens
            .Include(t => t.Service)
            .Where(t => t.ProviderId == counter.ProviderId && t.ServiceId == nextToken.ServiceId && t.Status == AppointmentStatus.InQueue)
            .OrderBy(t => t.Position)
            .ToListAsync();

        var activeStaff = await _db.ServiceCounters.CountAsync(c => c.ProviderId == counter.ProviderId && c.Status == CounterStatus.Active);

        // Fire ALL ML predictions in parallel (massive speedup!)
        var mlTasks = remainingTokens.Select((t, i) =>
            _mlService.PredictWaitTimeAsync(
                queueLength: i + 1,
                serviceType: t.Service?.Name ?? "general",
                priorityLevel: "normal",
                activeStaffCount: activeStaff > 0 ? activeStaff : 1
            )
        ).ToArray();

        int[] predictions;
        try
        {
            predictions = await Task.WhenAll(mlTasks);
        }
        catch
        {
            // If ML API is completely down, use fallback for all
            predictions = remainingTokens.Select((_, i) => (i + 1) * 15).ToArray();
        }

        for (int i = 0; i < remainingTokens.Count; i++)
        {
            remainingTokens[i].Position = i + 1;
            remainingTokens[i].EstimatedWaitMinutes = predictions[i];
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
            .Where(a => a.TokenNumber == token.TokenNumber && a.ProviderId == token.ProviderId)
            .OrderByDescending(a => a.CreatedAt)
            .FirstOrDefaultAsync();
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
    public async Task<bool> SkipTokenAsync(Guid tokenId, Guid staffUserId, string reason = "Absent — Customer not present")
    {
        var token = await _db.QueueTokens.FindAsync(tokenId);
        if (token == null) return false;

        token.Status = AppointmentStatus.Cancelled;
        token.CompletedAt = DateTime.UtcNow;
        token.SkipReason = reason;

        // Clear counter
        var counter = await _db.ServiceCounters
            .FirstOrDefaultAsync(c => c.ActiveTokenId == tokenId);

        if (counter != null)
            counter.ActiveTokenId = null;

        // Update related appointment
        var appointment = await _db.Appointments
            .Where(a => a.TokenNumber == token.TokenNumber && a.ProviderId == token.ProviderId)
            .OrderByDescending(a => a.CreatedAt)
            .FirstOrDefaultAsync();
        if (appointment != null)
        {
            appointment.Status = AppointmentStatus.Cancelled;
            appointment.SkipReason = reason;
        }

        // Log activity
        _db.ActivityLogs.Add(new ActivityLog
        {
            Action = $"Skipped {token.TokenNumber}: {reason}",
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
    /// Get user's active token (latest one)
    /// </summary>
    public async Task<QueueTokenDto?> GetUserActiveTokenAsync(Guid userId)
    {
        var token = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.Counter)
            .Where(t => t.UserId == userId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving))
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        return token == null ? null : MapToDto(token);
    }

    /// <summary>
    /// Get all user's active tokens
    /// </summary>
    public async Task<List<QueueTokenDto>> GetUserActiveTokensAsync(Guid userId)
    {
        var tokens = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Include(t => t.Counter)
            .Where(t => t.UserId == userId
                && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving))
            .OrderBy(t => t.CreatedAt)
            .ToListAsync();

        return tokens.Select(MapToDto).ToList();
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
            .Include(t => t.Counter)
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
            .Include(t => t.Counter)
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
        CounterNumber = token.Counter?.Number,
        SkipReason = token.SkipReason,
        CreatedAt = token.CreatedAt,
        ServedAt = token.ServedAt,
        CompletedAt = token.CompletedAt,
    };
}
