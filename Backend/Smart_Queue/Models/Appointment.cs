using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class Appointment
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(20)]
    public string TokenNumber { get; set; } = string.Empty;

    public DateTime Date { get; set; }

    public AppointmentStatus Status { get; set; } = AppointmentStatus.Upcoming;

    // FKs
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid ProviderId { get; set; }
    public ServiceProvider Provider { get; set; } = null!;

    public Guid ServiceId { get; set; }
    public Service Service { get; set; } = null!;

    public Guid? TimeSlotId { get; set; }
    public TimeSlot? TimeSlot { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
