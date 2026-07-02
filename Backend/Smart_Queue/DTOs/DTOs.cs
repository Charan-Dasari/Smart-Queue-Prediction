using System.ComponentModel.DataAnnotations;
using Smart_Queue.Models;

namespace Smart_Queue.DTOs;

// ── Auth DTOs ──
public class LoginRequest
{
    [Required]
    public string Identifier { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}

public class RegisterRequest
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(20)]
    public string Mobile { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public UserDto User { get; set; } = null!;
}

public class UserDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public Guid? ProviderId { get; set; }
    public string? ProviderName { get; set; }
}

public class UpdateProfileRequest
{
    [MaxLength(100)]
    public string? Name { get; set; }

    [MaxLength(20)]
    public string? Mobile { get; set; }

    [EmailAddress]
    public string? Email { get; set; }
}

public class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string NewPassword { get; set; } = string.Empty;
}

public class ResetPasswordVerifyRequest
{
    [Required]
    public string Name { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Mobile { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string NewPassword { get; set; } = string.Empty;
}

// ── Provider DTOs ──
public class ProviderDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public ServiceCategory Category { get; set; }
    public string Address { get; set; } = string.Empty;
    public double Rating { get; set; }
    public bool IsActive { get; set; }
    public int ActiveQueueCount { get; set; }
    public int EstimatedWaitMinutes { get; set; }
    public string? AdminEmail { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateProviderRequest
{
    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public ServiceCategory Category { get; set; }

    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;
}

public class ProviderWithServicesDto : ProviderDto
{
    public List<ServiceDto> Services { get; set; } = new();
}

// ── Service DTOs ──
public class ServiceDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int AvgDurationMinutes { get; set; }
    public decimal Cost { get; set; }
    public bool IsActive { get; set; }
    public Guid ProviderId { get; set; }
}

public class CreateServiceRequest
{
    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;

    public int AvgDurationMinutes { get; set; } = 15;
    public decimal Cost { get; set; } = 0;
    public bool IsActive { get; set; } = true;
}

public class UpdateServiceRequest
{
    [MaxLength(200)]
    public string? Name { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public int? AvgDurationMinutes { get; set; }
    public decimal? Cost { get; set; }
    public bool? IsActive { get; set; }
}

// ── TimeSlot DTOs ──
public class TimeSlotDto
{
    public Guid Id { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int TotalSlots { get; set; }
    public int AvailableSlots { get; set; }
    public double CrowdLevel { get; set; }
    public double AiScore { get; set; }
    public bool IsAvailable => AvailableSlots > 0;
}

// ── Appointment DTOs ──
public class AppointmentDto
{
    public Guid Id { get; set; }
    public string TokenNumber { get; set; } = string.Empty;
    public string ProviderName { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public AppointmentStatus Status { get; set; }
    public Guid ProviderId { get; set; }
    public Guid ServiceId { get; set; }
    public TimeSlotDto? TimeSlot { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BookAppointmentRequest
{
    [Required]
    public Guid ProviderId { get; set; }

    [Required]
    public Guid ServiceId { get; set; }

    [Required]
    public Guid TimeSlotId { get; set; }

    [Required]
    public DateTime Date { get; set; }
}

// ── Queue DTOs ──
public class QueueTokenDto
{
    public Guid Id { get; set; }
    public string TokenNumber { get; set; } = string.Empty;
    public string ProviderName { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public string? UserName { get; set; }
    public int Position { get; set; }
    public int EstimatedWaitMinutes { get; set; }
    public AppointmentStatus Status { get; set; }
    public Guid? CounterId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ServedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

// ── Counter DTOs ──
public class CounterDto
{
    public Guid Id { get; set; }
    public int Number { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public CounterStatus Status { get; set; }
    public string? StaffName { get; set; }
    public Guid? StaffUserId { get; set; }
    public string? ActiveTokenNumber { get; set; }
    public int TodayCustomers { get; set; }
    public int AvgServiceMinutes { get; set; }
}

public class CreateCounterRequest
{
    public int Number { get; set; }

    [MaxLength(200)]
    public string ServiceName { get; set; } = "General";
}

public class AssignCounterRequest
{
    public Guid? StaffUserId { get; set; }

    [MaxLength(200)]
    public string? ServiceName { get; set; }
}

public class UpdateCounterStatusRequest
{
    [Required]
    public CounterStatus Status { get; set; }
}

// ── Notification DTOs ──
public class NotificationDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public bool IsRead { get; set; }
    public DateTime Timestamp { get; set; }
}

// ── Dashboard DTOs ──
public class UserDashboardDto
{
    public int TotalAppointments { get; set; }
    public int CompletedVisits { get; set; }
    public int TimeSavedMinutes { get; set; }
    public QueueTokenDto? ActiveToken { get; set; }
    public List<AppointmentDto> UpcomingAppointments { get; set; } = new();
}

public class AdminDashboardDto
{
    public int TotalAppointmentsToday { get; set; }
    public int ActiveQueues { get; set; }
    public int AvgWaitMinutes { get; set; }
    public int TodayVisitors { get; set; }
    public int ServedToday { get; set; }
    public double SatisfactionScore { get; set; }
    public string ProviderName { get; set; } = string.Empty;
    public ServiceCategory ProviderCategory { get; set; }
}

public class StaffDashboardDto
{
    public string StaffName { get; set; } = string.Empty;
    public string ProviderName { get; set; } = string.Empty;
    public ServiceCategory ProviderCategory { get; set; }
    public CounterDto? AssignedCounter { get; set; }
    public string? CurrentlyServing { get; set; }
    public int WaitingCount { get; set; }
    public string? NextWaitingToken { get; set; }
    public int ServedToday { get; set; }
    public int AvgServiceMinutes { get; set; }
    public List<ActivityLogDto> RecentActivity { get; set; } = new();
}

public class SuperAdminDashboardDto
{
    public int TotalProviders { get; set; }
    public int HospitalCount { get; set; }
    public int BankCount { get; set; }
    public int CollegeCount { get; set; }
    public int GovtOfficeCount { get; set; }
    public int TotalUsers { get; set; }
    public List<ProviderDto> Providers { get; set; } = new();
}

public class ActivityLogDto
{
    public string Time { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
}

// ── Role Management DTOs ──
public class UpdateRoleRequest
{
    [Required]
    public UserRole Role { get; set; }
}
