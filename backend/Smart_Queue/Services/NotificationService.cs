using Smart_Queue.Data;
using Smart_Queue.Models;

namespace Smart_Queue.Services;

public class NotificationService
{
    private readonly SmartQueueDbContext _db;

    public NotificationService(SmartQueueDbContext db) => _db = db;

    public async Task CreateAsync(Guid userId, string title, string body, NotificationType type)
    {
        _db.Notifications.Add(new Notification
        {
            Title = title,
            Body = body,
            Type = type,
            UserId = userId,
            Timestamp = DateTime.UtcNow,
        });
        await _db.SaveChangesAsync();
    }

    public async Task CreateBookingNotificationAsync(Guid userId, string providerName, string serviceName, string tokenNumber)
    {
        await CreateAsync(userId,
            "Appointment Confirmed",
            $"Your appointment at {providerName} for {serviceName} has been confirmed. Token: {tokenNumber}",
            NotificationType.Booking);
    }

    public async Task CreateQueueUpdateAsync(Guid userId, int position, int estimatedWaitMinutes)
    {
        await CreateAsync(userId,
            "Queue Update",
            $"You are now #{position} in the queue. Estimated wait time: {estimatedWaitMinutes} minutes.",
            NotificationType.Queue);
    }
}
