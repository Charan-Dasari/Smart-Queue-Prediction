using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class Notification
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(1000)]
    public string Body { get; set; } = string.Empty;

    public NotificationType Type { get; set; }

    public bool IsRead { get; set; } = false;

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // FK
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
}
