using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class TimeSlot
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ServiceId { get; set; }
    public Service Service { get; set; } = null!;

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public int TotalSlots { get; set; } = 10;
    public int AvailableSlots { get; set; } = 10;

    /// <summary>0.0 to 1.0 — crowd density prediction</summary>
    public double CrowdLevel { get; set; } = 0.0;

    /// <summary>0.0 to 1.0 — AI recommendation score (higher = better)</summary>
    public double AiScore { get; set; } = 0.0;

    // Navigation
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}
