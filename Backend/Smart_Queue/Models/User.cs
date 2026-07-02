using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class User
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(200)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Mobile { get; set; } = string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    public UserRole Role { get; set; } = UserRole.User;

    // Navigation: which provider this user belongs to (null for regular users and super admin)
    public Guid? ProviderId { get; set; }
    public ServiceProvider? Provider { get; set; }

    // Navigation
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<QueueToken> QueueTokens { get; set; } = new List<QueueToken>();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
