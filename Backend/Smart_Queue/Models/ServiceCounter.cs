using System.ComponentModel.DataAnnotations;

namespace Smart_Queue.Models;

public class ServiceCounter
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public int Number { get; set; }

    [MaxLength(200)]
    public string ServiceName { get; set; } = "General";

    public CounterStatus Status { get; set; } = CounterStatus.Offline;

    public int TodayCustomers { get; set; } = 0;
    public int AvgServiceMinutes { get; set; } = 0;

    // FK: Provider
    public Guid ProviderId { get; set; }
    public ServiceProvider Provider { get; set; } = null!;

    // FK: Assigned staff (nullable = unassigned)
    public Guid? StaffUserId { get; set; }
    public User? StaffUser { get; set; }

    // FK: Currently serving token (nullable = idle)
    public Guid? ActiveTokenId { get; set; }
    public QueueToken? ActiveToken { get; set; }
}
