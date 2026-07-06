namespace Smart_Queue.Models;

public enum UserRole
{
    User,
    Admin,
    Staff,
    SuperAdmin
}

public enum ServiceCategory
{
    Hospital,
    Bank,
    GovtOffice,
    College,
    Restaurant,
    Hotel,
    Other
}

public enum AppointmentStatus
{
    Upcoming,
    InQueue,
    Serving,
    Completed,
    Cancelled
}

public enum CounterStatus
{
    Active,
    OnBreak,
    Offline
}

public enum NotificationType
{
    Booking,
    Queue,
    Reminder,
    System,
    AI
}

public enum QueueTimelineStep
{
    Booked,
    CheckedIn,
    Waiting,
    Serving,
    Completed
}
