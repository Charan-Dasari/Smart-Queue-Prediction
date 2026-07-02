using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;
using ServiceProvider = Smart_Queue.Models.ServiceProvider;

namespace Smart_Queue.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(SmartQueueDbContext db)
    {
        if (await db.Users.AnyAsync())
            return; // Already seeded

        // ── 1. Service Providers ──
        var hospital = new ServiceProvider
        {
            Id = Guid.NewGuid(),
            Name = "Metro City Hospital",
            Category = ServiceCategory.Hospital,
            Address = "123 Medical Lane, Metro City",
            Rating = 4.8
        };

        var bank = new ServiceProvider
        {
            Id = Guid.NewGuid(),
            Name = "Apex Global Bank",
            Category = ServiceCategory.Bank,
            Address = "456 Finance Street, Metro City",
            Rating = 4.5
        };

        var govt = new ServiceProvider
        {
            Id = Guid.NewGuid(),
            Name = "District Collector Office",
            Category = ServiceCategory.GovtOffice,
            Address = "789 Government Plaza, Metro City",
            Rating = 4.2
        };

        db.ServiceProviders.AddRange(hospital, bank, govt);

        // ── 2. Users (passwords hashed with BCrypt) ──
        var users = new List<User>
        {
            new() { Name = "Rahul Sharma",          Email = "rahul@email.com",          Mobile = "+91 98765 43210", PasswordHash = BCrypt.Net.BCrypt.HashPassword("user123"),  Role = UserRole.User,       ProviderId = null },
            new() { Name = "Priya Patel",           Email = "priya@email.com",          Mobile = "+91 87654 32100", PasswordHash = BCrypt.Net.BCrypt.HashPassword("user123"),  Role = UserRole.User,       ProviderId = null },
            new() { Name = "Amit Kumar",            Email = "amit@email.com",           Mobile = "+91 76543 21000", PasswordHash = BCrypt.Net.BCrypt.HashPassword("user123"),  Role = UserRole.User,       ProviderId = null },
            new() { Name = "Hospital Admin",        Email = "admin@intelliq.com",       Mobile = "+91 99999 00000", PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"), Role = UserRole.Admin,      ProviderId = hospital.Id },
            new() { Name = "Bank Admin",            Email = "bankadmin@intelliq.com",   Mobile = "+91 99999 11111", PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"), Role = UserRole.Admin,      ProviderId = bank.Id },
            new() { Name = "Govt Admin",            Email = "govtadmin@intelliq.com",   Mobile = "+91 99999 22222", PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"), Role = UserRole.Admin,      ProviderId = govt.Id },
            new() { Name = "Sarah Jenkins",         Email = "staff@intelliq.com",       Mobile = "+91 88888 00000", PasswordHash = BCrypt.Net.BCrypt.HashPassword("staff123"), Role = UserRole.Staff,      ProviderId = hospital.Id },
            new() { Name = "David Lee",             Email = "bankstaff@intelliq.com",   Mobile = "+91 88888 11111", PasswordHash = BCrypt.Net.BCrypt.HashPassword("staff123"), Role = UserRole.Staff,      ProviderId = bank.Id },
            new() { Name = "James Carter",          Email = "govtstaff@intelliq.com",   Mobile = "+91 88888 22222", PasswordHash = BCrypt.Net.BCrypt.HashPassword("staff123"), Role = UserRole.Staff,      ProviderId = govt.Id },
            new() { Name = "Platform Super Admin",  Email = "super@intelliq.com",       Mobile = "+91 90000 00000", PasswordHash = BCrypt.Net.BCrypt.HashPassword("super123"), Role = UserRole.SuperAdmin, ProviderId = null },
        };

        db.Users.AddRange(users);

        // ── 3. Services per Provider ──
        // Hospital
        var hospitalServices = new List<Service>
        {
            new() { Name = "General Consultation",  Description = "Basic medical checkup & advice",          AvgDurationMinutes = 15, Cost = 200,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Specialist Checkup",    Description = "Specialized medical examination",         AvgDurationMinutes = 30, Cost = 500,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Lab Test",              Description = "Blood work & diagnostic tests",           AvgDurationMinutes = 20, Cost = 350,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Follow-up Visit",       Description = "Post-treatment follow-up",                AvgDurationMinutes = 10, Cost = 100,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Dental Checkup",        Description = "Dental examination & cleaning",           AvgDurationMinutes = 25, Cost = 400,  IsActive = false, ProviderId = hospital.Id },
        };

        // Bank
        var bankServices = new List<Service>
        {
            new() { Name = "Cash Deposit",          Description = "Deposit physical currency",               AvgDurationMinutes = 8,  Cost = 0,    IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Account Opening",       Description = "Open savings/current accounts",           AvgDurationMinutes = 20, Cost = 100,  IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Loan Query",            Description = "Consultation on housing/personal loans",  AvgDurationMinutes = 30, Cost = 0,    IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Card Issue",            Description = "Collect or replace debit/credit cards",   AvgDurationMinutes = 10, Cost = 150,  IsActive = false, ProviderId = bank.Id },
        };

        // Govt Office
        var govtServices = new List<Service>
        {
            new() { Name = "Document Verification", Description = "Verify government records & identity",    AvgDurationMinutes = 15, Cost = 50,   IsActive = true,  ProviderId = govt.Id },
            new() { Name = "License Renewal",       Description = "Driving or professional license renewal", AvgDurationMinutes = 25, Cost = 250,  IsActive = true,  ProviderId = govt.Id },
            new() { Name = "Govt Grant Inquiry",    Description = "Apply for or query welfare schemes",      AvgDurationMinutes = 20, Cost = 0,    IsActive = true,  ProviderId = govt.Id },
            new() { Name = "Certificate Issue",     Description = "Birth/Marriage/Income certificates",      AvgDurationMinutes = 12, Cost = 30,   IsActive = false, ProviderId = govt.Id },
        };

        db.Services.AddRange(hospitalServices);
        db.Services.AddRange(bankServices);
        db.Services.AddRange(govtServices);

        // ── 4. Service Counters ──
        var staffSarah = users[6];  // Sarah Jenkins (hospital staff)
        var staffDavid = users[7];  // David Lee (bank staff)
        var staffJames = users[8];  // James Carter (govt staff)

        var counters = new List<ServiceCounter>
        {
            new() { Number = 1, ServiceName = "General Consultation",    Status = CounterStatus.Active,  ProviderId = hospital.Id, StaffUserId = staffSarah.Id, TodayCustomers = 18, AvgServiceMinutes = 8 },
            new() { Number = 2, ServiceName = "Lab Test",                Status = CounterStatus.OnBreak, ProviderId = hospital.Id, StaffUserId = null,          TodayCustomers = 12, AvgServiceMinutes = 9 },
            new() { Number = 3, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = hospital.Id, StaffUserId = null,          TodayCustomers = 0,  AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Account Service",         Status = CounterStatus.Active,  ProviderId = bank.Id,     StaffUserId = staffDavid.Id, TodayCustomers = 18, AvgServiceMinutes = 8 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = bank.Id,     StaffUserId = null,          TodayCustomers = 0,  AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Document Verification",   Status = CounterStatus.Active,  ProviderId = govt.Id,     StaffUserId = staffJames.Id, TodayCustomers = 22, AvgServiceMinutes = 7 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = govt.Id,     StaffUserId = null,          TodayCustomers = 0,  AvgServiceMinutes = 0 },
        };

        db.ServiceCounters.AddRange(counters);

        // ── 5. Sample Notifications (for user Rahul) ──
        var rahul = users[0];
        var notifications = new List<Notification>
        {
            new() { Title = "Appointment Confirmed",       Body = "Your appointment at Metro City Hospital for General Consultation has been confirmed for tomorrow at 10:00 AM.", Type = NotificationType.Booking, UserId = rahul.Id, Timestamp = DateTime.UtcNow.AddHours(-2) },
            new() { Title = "Queue Update",                Body = "You are now #3 in the queue. Estimated wait time: 12 minutes.",                                                Type = NotificationType.Queue,   UserId = rahul.Id, Timestamp = DateTime.UtcNow.AddHours(-1) },
            new() { Title = "AI Smart Suggestion",         Body = "Based on crowd predictions, 2:00 PM - 3:00 PM has 40% less crowd than your usual visit time.",                 Type = NotificationType.AI,      UserId = rahul.Id, Timestamp = DateTime.UtcNow.AddMinutes(-30) },
            new() { Title = "Upcoming Appointment Reminder",Body = "Reminder: You have an appointment at Apex Global Bank tomorrow at 11:30 AM.",                                 Type = NotificationType.Reminder,UserId = rahul.Id, Timestamp = DateTime.UtcNow.AddMinutes(-15) },
        };

        db.Notifications.AddRange(notifications);

        // ── 6. Generate Time Slots for today + next 7 days ──
        var allServices = hospitalServices.Concat(bankServices).Concat(govtServices).ToList();
        var today = DateTime.UtcNow.Date;

        foreach (var service in allServices.Where(s => s.IsActive))
        {
            for (int day = 0; day < 7; day++)
            {
                var date = today.AddDays(day);
                // Generate slots from 9 AM to 5 PM
                for (int hour = 9; hour < 17; hour++)
                {
                    var start = date.AddHours(hour);
                    var end = start.AddHours(1);
                    var crowdLevel = hour switch
                    {
                        >= 10 and <= 12 => 0.8,  // Peak morning
                        >= 14 and <= 15 => 0.6,  // Moderate afternoon
                        _ => 0.3                  // Low
                    };
                    var aiScore = 1.0 - crowdLevel; // Inverse of crowd

                    db.TimeSlots.Add(new TimeSlot
                    {
                        ServiceId = service.Id,
                        StartTime = start,
                        EndTime = end,
                        TotalSlots = 10,
                        AvailableSlots = (int)(10 * (1.0 - crowdLevel * 0.7)), // More crowd → fewer slots
                        CrowdLevel = crowdLevel,
                        AiScore = aiScore,
                    });
                }
            }
        }

        await db.SaveChangesAsync();
    }
}
