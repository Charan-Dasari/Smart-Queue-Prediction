using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class AccountDeletionRequest
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public DeletionStatus Status { get; set; } = DeletionStatus.Pending;

    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ScheduledDeletionDate { get; set; }

    public DateTime? ApprovedAt { get; set; }

    [MaxLength(500)]
    public string? Reason { get; set; }
}
