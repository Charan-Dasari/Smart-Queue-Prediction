using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class Place
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(500)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Category { get; set; } = string.Empty; // Hospital, Bank, Restaurant, College

    [MaxLength(200)]
    public string State { get; set; } = string.Empty;

    [MaxLength(200)]
    public string City { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string Address { get; set; } = string.Empty;

    public double Rating { get; set; } = 0.0; // 0 means no rating available

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
