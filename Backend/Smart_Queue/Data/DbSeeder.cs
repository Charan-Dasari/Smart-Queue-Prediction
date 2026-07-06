using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;
using ServiceProvider = Smart_Queue.Models.ServiceProvider;

namespace Smart_Queue.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(SmartQueueDbContext db)
    {
        // Only seed provider-related data if no services exist
        // (Users are managed via registration + SQL, so don't check users)
        if (await db.Services.AnyAsync())
            return; // Already seeded

        // ── 1. Get or Create Service Providers ──
        var hospital = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.Hospital);
        var bank = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.Bank);
        var govt = await db.ServiceProviders.FirstOrDefaultAsync(p => p.Category == ServiceCategory.GovtOffice);

        if (hospital == null)
        {
            hospital = new ServiceProvider
            {
                Id = Guid.NewGuid(),
                Name = "Metro City Hospital",
                Category = ServiceCategory.Hospital,
                Address = "123 Medical Lane, Metro City",
                Rating = 4.8
            };
            db.ServiceProviders.Add(hospital);
        }

        if (bank == null)
        {
            bank = new ServiceProvider
            {
                Id = Guid.NewGuid(),
                Name = "Apex Global Bank",
                Category = ServiceCategory.Bank,
                Address = "456 Finance Street, Metro City",
                Rating = 4.5
            };
            db.ServiceProviders.Add(bank);
        }

        if (govt == null)
        {
            govt = new ServiceProvider
            {
                Id = Guid.NewGuid(),
                Name = "District Collector Office",
                Category = ServiceCategory.GovtOffice,
                Address = "789 Government Plaza, Metro City",
                Rating = 4.2
            };
            db.ServiceProviders.Add(govt);
        }

        await db.SaveChangesAsync(); // Save providers first so IDs are available

        // ── 2. Services per Provider ──
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

        // ── 3. Service Counters ──
        // Link counters to staff users if they exist
        var staffUser = await db.Users.FirstOrDefaultAsync(u => u.Role == UserRole.Staff && u.ProviderId == hospital.Id);

        var counters = new List<ServiceCounter>
        {
            new() { Number = 1, ServiceName = "General Consultation",    Status = CounterStatus.Active,  ProviderId = hospital.Id, StaffUserId = staffUser?.Id, TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "Lab Test",                Status = CounterStatus.OnBreak, ProviderId = hospital.Id, StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 3, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = hospital.Id, StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Account Service",         Status = CounterStatus.Active,  ProviderId = bank.Id,     StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = bank.Id,     StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 1, ServiceName = "Document Verification",   Status = CounterStatus.Active,  ProviderId = govt.Id,     StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
            new() { Number = 2, ServiceName = "None",                    Status = CounterStatus.Offline, ProviderId = govt.Id,     StaffUserId = null,          TodayCustomers = 0, AvgServiceMinutes = 0 },
        };

        db.ServiceCounters.AddRange(counters);

        // ── 4. Generate Time Slots for today + next 7 days ──
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
