using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class AppointmentCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AppointmentCleanupService> _logger;

    public AppointmentCleanupService(IServiceProvider serviceProvider, ILogger<AppointmentCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AppointmentCleanupService started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CleanupExpiredAppointmentsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while cleaning up expired appointments.");
            }

            // Run every 5 minutes
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }

        _logger.LogInformation("AppointmentCleanupService is stopping.");
    }

    private async Task CleanupExpiredAppointmentsAsync(CancellationToken stoppingToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SmartQueueDbContext>();

        // Find appointments that are strictly in the past and still upcoming or in queue
        var expiredAppointments = await db.Appointments
            .Where(a => (a.Status == AppointmentStatus.Upcoming || a.Status == AppointmentStatus.InQueue)
                        && a.Date < DateTime.UtcNow)
            .ToListAsync(stoppingToken);

        if (expiredAppointments.Any())
        {
            foreach (var appointment in expiredAppointments)
            {
                appointment.Status = AppointmentStatus.Cancelled;

                // Also cancel related active QueueToken if it exists
                var token = await db.QueueTokens.FirstOrDefaultAsync(t => 
                    t.TokenNumber == appointment.TokenNumber && 
                    t.ProviderId == appointment.ProviderId &&
                    t.CreatedAt.Date == appointment.CreatedAt.Date, stoppingToken);

                if (token != null && (token.Status == AppointmentStatus.Upcoming || token.Status == AppointmentStatus.InQueue))
                {
                    token.Status = AppointmentStatus.Cancelled;
                    token.CompletedAt = DateTime.UtcNow;

                    // Remove from counter if serving (though should not happen if Date is strictly in past and unhandled)
                    var counter = await db.ServiceCounters.FirstOrDefaultAsync(c => c.ActiveTokenId == token.Id, stoppingToken);
                    if (counter != null)
                    {
                        counter.ActiveTokenId = null;
                    }
                }
            }

            await db.SaveChangesAsync(stoppingToken);
            _logger.LogInformation($"Cleaned up {expiredAppointments.Count} expired appointments.");
        }
    }
}
