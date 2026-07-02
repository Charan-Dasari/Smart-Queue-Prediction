using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class DashboardService
{
    private readonly SmartQueueDbContext _db;

    public DashboardService(SmartQueueDbContext db) => _db = db;

    public async Task<UserDashboardDto> GetUserDashboardAsync(Guid userId)
    {
        var todayStart = DateTime.UtcNow.Date;

        var totalAppointments = await _db.Appointments.CountAsync(a => a.UserId == userId);
        var completedVisits = await _db.Appointments.CountAsync(a => a.UserId == userId && a.Status == AppointmentStatus.Completed);

        var activeToken = await _db.QueueTokens
            .Include(t => t.Provider)
            .Include(t => t.Service)
            .Where(t => t.UserId == userId && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving))
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        var upcomingAppointments = await _db.Appointments
            .Include(a => a.Provider)
            .Include(a => a.Service)
            .Include(a => a.TimeSlot)
            .Where(a => a.UserId == userId && a.Status == AppointmentStatus.Upcoming && a.Date >= todayStart)
            .OrderBy(a => a.Date)
            .Take(5)
            .ToListAsync();

        return new UserDashboardDto
        {
            TotalAppointments = totalAppointments,
            CompletedVisits = completedVisits,
            TimeSavedMinutes = completedVisits * 12, // Rough estimate of time saved per visit
            ActiveToken = activeToken != null ? QueueService.MapToDto(activeToken) : null,
            UpcomingAppointments = upcomingAppointments.Select(a => new AppointmentDto
            {
                Id = a.Id,
                TokenNumber = a.TokenNumber,
                ProviderName = a.Provider?.Name ?? "",
                ServiceName = a.Service?.Name ?? "",
                Date = a.Date,
                Status = a.Status,
                ProviderId = a.ProviderId,
                ServiceId = a.ServiceId,
                CreatedAt = a.CreatedAt,
            }).ToList(),
        };
    }

    public async Task<AdminDashboardDto> GetAdminDashboardAsync(Guid providerId)
    {
        var todayStart = DateTime.UtcNow.Date;
        var provider = await _db.ServiceProviders.FindAsync(providerId);

        var todayAppointments = await _db.Appointments.CountAsync(a => a.ProviderId == providerId && a.Date >= todayStart);
        var activeQueues = await _db.QueueTokens.CountAsync(t => t.ProviderId == providerId && (t.Status == AppointmentStatus.InQueue || t.Status == AppointmentStatus.Serving));
        var servedToday = await _db.QueueTokens.CountAsync(t => t.ProviderId == providerId && t.Status == AppointmentStatus.Completed && t.CompletedAt >= todayStart);

        var avgWait = await _db.QueueTokens
            .Where(t => t.ProviderId == providerId && t.Status == AppointmentStatus.Completed && t.CompletedAt >= todayStart && t.ServedAt != null)
            .Select(t => EF.Functions.DateDiffMinute(t.CreatedAt, t.ServedAt!.Value))
            .DefaultIfEmpty(0)
            .AverageAsync();

        return new AdminDashboardDto
        {
            TotalAppointmentsToday = todayAppointments,
            ActiveQueues = activeQueues,
            AvgWaitMinutes = (int)avgWait,
            TodayVisitors = servedToday + activeQueues,
            ServedToday = servedToday,
            SatisfactionScore = 4.6,
            ProviderName = provider?.Name ?? "",
            ProviderCategory = provider?.Category ?? ServiceCategory.Other,
        };
    }

    public async Task<StaffDashboardDto> GetStaffDashboardAsync(Guid staffUserId)
    {
        var user = await _db.Users.Include(u => u.Provider).FirstOrDefaultAsync(u => u.Id == staffUserId);
        if (user?.ProviderId == null) return new StaffDashboardDto();

        var providerId = user.ProviderId.Value;

        var counter = await _db.ServiceCounters
            .Include(c => c.ActiveToken)
            .FirstOrDefaultAsync(c => c.StaffUserId == staffUserId);

        var waitingCount = await _db.QueueTokens
            .CountAsync(t => t.ProviderId == providerId && t.Status == AppointmentStatus.InQueue);

        var nextWaiting = await _db.QueueTokens
            .Where(t => t.ProviderId == providerId && t.Status == AppointmentStatus.InQueue)
            .OrderBy(t => t.Position)
            .Select(t => t.TokenNumber)
            .FirstOrDefaultAsync();

        var recentActivity = await _db.ActivityLogs
            .Where(a => a.ProviderId == providerId && a.UserId == staffUserId)
            .OrderByDescending(a => a.Timestamp)
            .Take(10)
            .ToListAsync();

        return new StaffDashboardDto
        {
            StaffName = user.Name,
            ProviderName = user.Provider?.Name ?? "",
            ProviderCategory = user.Provider?.Category ?? ServiceCategory.Other,
            AssignedCounter = counter != null ? new CounterDto
            {
                Id = counter.Id,
                Number = counter.Number,
                ServiceName = counter.ServiceName,
                Status = counter.Status,
                TodayCustomers = counter.TodayCustomers,
                AvgServiceMinutes = counter.AvgServiceMinutes,
                ActiveTokenNumber = counter.ActiveToken?.TokenNumber,
            } : null,
            CurrentlyServing = counter?.ActiveToken?.TokenNumber,
            WaitingCount = waitingCount,
            NextWaitingToken = nextWaiting,
            ServedToday = counter?.TodayCustomers ?? 0,
            AvgServiceMinutes = counter?.AvgServiceMinutes ?? 0,
            RecentActivity = recentActivity.Select(a => new ActivityLogDto
            {
                Time = a.Timestamp.ToString("hh:mm tt"),
                Action = a.Action,
            }).ToList(),
        };
    }

    public async Task<SuperAdminDashboardDto> GetSuperAdminDashboardAsync()
    {
        var providers = await _db.ServiceProviders.ToListAsync();
        var totalUsers = await _db.Users.CountAsync();

        // Get admin email for each provider
        var adminEmails = await _db.Users
            .Where(u => u.Role == UserRole.Admin && u.ProviderId != null)
            .GroupBy(u => u.ProviderId)
            .Select(g => new { ProviderId = g.Key, Email = g.First().Email })
            .ToDictionaryAsync(x => x.ProviderId!.Value, x => x.Email);

        return new SuperAdminDashboardDto
        {
            TotalProviders = providers.Count,
            HospitalCount = providers.Count(p => p.Category == ServiceCategory.Hospital),
            BankCount = providers.Count(p => p.Category == ServiceCategory.Bank),
            CollegeCount = providers.Count(p => p.Category == ServiceCategory.College),
            GovtOfficeCount = providers.Count(p => p.Category == ServiceCategory.GovtOffice),
            TotalUsers = totalUsers,
            Providers = providers.Select(p => new ProviderDto
            {
                Id = p.Id,
                Name = p.Name,
                Category = p.Category,
                Address = p.Address,
                Rating = p.Rating,
                IsActive = p.IsActive,
                AdminEmail = adminEmails.GetValueOrDefault(p.Id),
                CreatedAt = p.CreatedAt,
            }).ToList(),
        };
    }
}
