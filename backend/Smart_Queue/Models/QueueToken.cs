using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class QueueToken
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(20)]
    public string TokenNumber { get; set; } = string.Empty;

    public int Position { get; set; }
    public int EstimatedWaitMinutes { get; set; }

    public AppointmentStatus Status { get; set; } = AppointmentStatus.InQueue;

    // FKs
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid ProviderId { get; set; }
    public ServiceProvider Provider { get; set; } = null!;

    public Guid ServiceId { get; set; }
    public Service Service { get; set; } = null!;

    public Guid? CounterId { get; set; }
    public ServiceCounter? Counter { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ServedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}
