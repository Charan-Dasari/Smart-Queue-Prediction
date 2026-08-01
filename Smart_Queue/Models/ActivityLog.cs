using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class ActivityLog
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(500)]
    public string Action { get; set; } = string.Empty;

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // FK
    public Guid ProviderId { get; set; }
    public ServiceProvider Provider { get; set; } = null!;

    public Guid? UserId { get; set; }
    public User? User { get; set; }
}
