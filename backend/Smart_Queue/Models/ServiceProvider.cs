using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class ServiceProvider
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    public ServiceCategory Category { get; set; }

    public long? OsmNodeId { get; set; }

    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    public double Rating { get; set; } = 5.0;

    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public bool IsActive { get; set; } = true;

    // Navigation
    public ICollection<Service> Services { get; set; } = new List<Service>();
    public ICollection<ServiceCounter> Counters { get; set; } = new List<ServiceCounter>();
    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<QueueToken> QueueTokens { get; set; } = new List<QueueToken>();
    public ICollection<ActivityLog> ActivityLogs { get; set; } = new List<ActivityLog>();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
