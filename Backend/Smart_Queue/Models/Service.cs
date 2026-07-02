using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class Service
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;

    public int AvgDurationMinutes { get; set; } = 15;

    public decimal Cost { get; set; } = 0;

    public bool IsActive { get; set; } = true;

    // FK
    public Guid ProviderId { get; set; }
    public ServiceProvider Provider { get; set; } = null!;

    // Navigation
    public ICollection<TimeSlot> TimeSlots { get; set; } = new List<TimeSlot>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<QueueToken> QueueTokens { get; set; } = new List<QueueToken>();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
