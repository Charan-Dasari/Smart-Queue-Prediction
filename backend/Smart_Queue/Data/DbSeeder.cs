using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;

namespace Smart_Queue.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(SmartQueueDbContext db)
    {
        // ── Seed Super Admin Only ─────────────────────────────────────────────
        const string superAdminEmail = "super@intelliq.com";

        if (!await db.Users.AnyAsync(x => x.Email.ToLower() == superAdminEmail))
        {
            db.Users.Add(new User
            {
                Name = "Super Admin",
                Email = superAdminEmail,
                Mobile = "9000000099",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("SuperAdmin@1234"),
                Role = UserRole.SuperAdmin,
                ProviderId = null
            });

            await db.SaveChangesAsync();
            Console.WriteLine($"[DbSeeder] Seeded Super Admin: {superAdminEmail}");
        }
        else
        {
            Console.WriteLine($"[DbSeeder] Super Admin already exists ({superAdminEmail}). Skipping.");
        }
    }
}