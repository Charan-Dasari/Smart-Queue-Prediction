using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;
using ServiceProvider = Smart_Queue.Models.ServiceProvider;

namespace Smart_Queue.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(SmartQueueDbContext db)
    {
        // ── 1. Seed Test Users (all roles) ─────────────────────────────────────
        await SeedUsersAsync(db);

        // Only seed provider-related data if no services exist
        if (await db.Services.AnyAsync())
            return; // Providers + services already seeded

        // ── 2. Get or Create Service Providers ─────────────────────────────────
        var hospital = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.Hospital);
        var bank     = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.Bank);
        var govt     = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.GovtOffice);

        if (hospital == null)
        {
            hospital = new ServiceProvider
            {
                Id       = Guid.NewGuid(),
                Name     = "Metro City Hospital",
                Category = ServiceCategory.Hospital,
                Address  = "123 Medical Lane, Metro City",
                Rating   = 4.8
            };
            db.ServiceProviders.Add(hospital);
        }

        if (bank == null)
        {
            bank = new ServiceProvider
            {
                Id       = Guid.NewGuid(),
                Name     = "Apex Global Bank",
                Category = ServiceCategory.Bank,
                Address  = "456 Finance Street, Metro City",
                Rating   = 4.5
            };
            db.ServiceProviders.Add(bank);
        }

        if (govt == null)
        {
            govt = new ServiceProvider
            {
                Id       = Guid.NewGuid(),
                Name     = "District Collector Office",
                Category = ServiceCategory.GovtOffice,
                Address  = "789 Government Plaza, Metro City",
                Rating   = 4.2
            };
            db.ServiceProviders.Add(govt);
        }

        await db.SaveChangesAsync(); // Save providers first so IDs are available

        // ── 3. Assign Admin & Staff to providers ────────────────────────────────
        var adminUser = await db.Users.FirstOrDefaultAsync(u => u.Email == "admin@intelliq.com");
        var staffUser = await db.Users.FirstOrDefaultAsync(u => u.Email == "staff@intelliq.com");

        if (adminUser != null && adminUser.ProviderId == null)
        {
            adminUser.ProviderId = hospital.Id;
        }
        if (staffUser != null && staffUser.ProviderId == null)
        {
            staffUser.ProviderId = hospital.Id;
        }
        await db.SaveChangesAsync();

        // ── 4. Services per Provider ────────────────────────────────────────────
        var hospitalServices = new List<Service>
        {
            new() { Name = "General Consultation",  Description = "Basic medical checkup & advice",          AvgDurationMinutes = 15, Cost = 200,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Specialist Checkup",    Description = "Specialized medical examination",         AvgDurationMinutes = 30, Cost = 500,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Lab Test",              Description = "Blood work & diagnostic tests",           AvgDurationMinutes = 20, Cost = 350,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Follow-up Visit",       Description = "Post-treatment follow-up",                AvgDurationMinutes = 10, Cost = 100,  IsActive = true,  ProviderId = hospital.Id },
            new() { Name = "Dental Checkup",        Description = "Dental examination & cleaning",           AvgDurationMinutes = 25, Cost = 400,  IsActive = false, ProviderId = hospital.Id },
        };

        var bankServices = new List<Service>
        {
            new() { Name = "Cash Deposit",          Description = "Deposit physical currency",               AvgDurationMinutes = 8,  Cost = 0,    IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Account Opening",       Description = "Open savings/current accounts",           AvgDurationMinutes = 20, Cost = 100,  IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Loan Query",            Description = "Consultation on housing/personal loans",  AvgDurationMinutes = 30, Cost = 0,    IsActive = true,  ProviderId = bank.Id },
            new() { Name = "Card Issue",            Description = "Collect or replace debit/credit cards",   AvgDurationMinutes = 10, Cost = 150,  IsActive = false, ProviderId = bank.Id },
        };

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

        // ── 5. Service Counters ──────────────────────────────────────────────────
        var freshStaff = await db.Users.FirstOrDefaultAsync(u => u.Email == "staff@intelliq.com");

        var counters = new List<ServiceCounter>
        {
            new() { Number = 1, ServiceName = "General Consultation",    Status = CounterStatus.Active,  ProviderId = hospital.Id, StaffUserId = freshStaff?.Id, TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "Lab Test",                Status = CounterStatus.OnBreak, ProviderId = hospital.Id, StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 3, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = hospital.Id, StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Account Service",         Status = CounterStatus.Active,  ProviderId = bank.Id,     StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = bank.Id,     StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Document Verification",   Status = CounterStatus.Active,  ProviderId = govt.Id,     StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = govt.Id,     StaffUserId = null,           TodayCustomers = 0, AvgServiceMinutes = 0 },
        };

        db.ServiceCounters.AddRange(counters);

        // ── 6. Generate Time Slots (today + next 7 days) ─────────────────────────
        var allServices = hospitalServices.Concat(bankServices).Concat(govtServices).ToList();
        var today = DateTime.UtcNow.Date;

        foreach (var service in allServices.Where(s => s.IsActive))
        {
            for (int day = 0; day < 7; day++)
            {
                var date = today.AddDays(day);
                for (int hour = 9; hour < 17; hour++)
                {
                    var start = date.AddHours(hour);
                    var end   = start.AddHours(1);
                    var crowdLevel = hour switch
                    {
                        >= 10 and <= 12 => 0.8,
                        >= 14 and <= 15 => 0.6,
                        _               => 0.3
                    };

                    db.TimeSlots.Add(new TimeSlot
                    {
                        ServiceId       = service.Id,
                        StartTime       = start,
                        EndTime         = end,
                        TotalSlots      = 10,
                        AvailableSlots  = (int)(10 * (1.0 - crowdLevel * 0.7)),
                        CrowdLevel      = crowdLevel,
                        AiScore         = 1.0 - crowdLevel,
                    });
                }
            }
        }

        await db.SaveChangesAsync();
        Console.WriteLine("[DbSeeder] Providers, Services, Counters and TimeSlots seeded successfully.");
    }

    // ── User seeding (idempotent — skips existing emails) ───────────────────────
    private static async Task SeedUsersAsync(SmartQueueDbContext db)
    {
        var usersToSeed = new[]
        {
            // ── Regular Users ────────────────────────────────────────────────
            new { Name = "Aarav Sharma",   Email = "aarav@intelliq.com",   Mobile = "9000000001", Password = "User@1234",       Role = UserRole.User       },
            new { Name = "Priya Patel",    Email = "priya@intelliq.com",   Mobile = "9000000002", Password = "User@1234",       Role = UserRole.User       },
            new { Name = "Rahul Mehta",    Email = "rahul@intelliq.com",   Mobile = "9000000003", Password = "User@1234",       Role = UserRole.User       },
            new { Name = "Sneha Verma",    Email = "sneha@intelliq.com",   Mobile = "9000000004", Password = "User@1234",       Role = UserRole.User       },

            // ── Admin ────────────────────────────────────────────────────────
            new { Name = "Admin IntelliQ", Email = "admin@intelliq.com",   Mobile = "9000000010", Password = "Admin@1234",      Role = UserRole.Admin      },

            // ── Staff ────────────────────────────────────────────────────────
            new { Name = "Staff Member",   Email = "staff@intelliq.com",   Mobile = "9000000011", Password = "Staff@1234",      Role = UserRole.Staff      },

            // ── Super Admin ───────────────────────────────────────────────────
            new { Name = "Super Admin",    Email = "super@intelliq.com",   Mobile = "9000000099", Password = "SuperAdmin@1234", Role = UserRole.SuperAdmin },
        };

        foreach (var u in usersToSeed)
        {
            if (!await db.Users.AnyAsync(x => x.Email.ToLower() == u.Email.ToLower()))
            {
                db.Users.Add(new User
                {
                    Name         = u.Name,
                    Email        = u.Email,
                    Mobile       = u.Mobile,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(u.Password),
                    Role         = u.Role,
                    ProviderId   = null // Provider assignment done after providers are created
                });
                Console.WriteLine($"[DbSeeder] Seeded user: {u.Email} ({u.Role})");
            }
        }

        await db.SaveChangesAsync();
    }
}
