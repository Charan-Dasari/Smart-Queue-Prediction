using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;
using ServiceProvider = Smart_Queue.Models.ServiceProvider;

namespace Smart_Queue.Data;

public class SmartQueueDbContext : DbContext
{
    public SmartQueueDbContext(DbContextOptions<SmartQueueDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<ServiceProvider> ServiceProviders => Set<ServiceProvider>();
    public DbSet<Service> Services => Set<Service>();
    public DbSet<TimeSlot> TimeSlots => Set<TimeSlot>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<QueueToken> QueueTokens => Set<QueueToken>();
    public DbSet<ServiceCounter> ServiceCounters => Set<ServiceCounter>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── User ──
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
            e.Property(u => u.Role).HasConversion<string>().HasMaxLength(20);
        });

        // ── ServiceProvider ──
        modelBuilder.Entity<ServiceProvider>(e =>
        {
            e.Property(p => p.Category).HasConversion<string>().HasMaxLength(20);
        });

        // ── Service ──
        modelBuilder.Entity<Service>(e =>
        {
            e.HasOne(s => s.Provider)
             .WithMany(p => p.Services)
             .HasForeignKey(s => s.ProviderId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── TimeSlot ──
        modelBuilder.Entity<TimeSlot>(e =>
        {
            e.HasOne(t => t.Service)
             .WithMany(s => s.TimeSlots)
             .HasForeignKey(t => t.ServiceId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Appointment ──
        modelBuilder.Entity<Appointment>(e =>
        {
            e.Property(a => a.Status).HasConversion<string>().HasMaxLength(20);

            e.HasOne(a => a.User)
             .WithMany(u => u.Appointments)
             .HasForeignKey(a => a.UserId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(a => a.Provider)
             .WithMany(p => p.Appointments)
             .HasForeignKey(a => a.ProviderId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(a => a.Service)
             .WithMany(s => s.Appointments)
             .HasForeignKey(a => a.ServiceId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(a => a.TimeSlot)
             .WithMany(t => t.Appointments)
             .HasForeignKey(a => a.TimeSlotId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── QueueToken ──
        modelBuilder.Entity<QueueToken>(e =>
        {
            e.Property(q => q.Status).HasConversion<string>().HasMaxLength(20);

            e.HasOne(q => q.User)
             .WithMany(u => u.QueueTokens)
             .HasForeignKey(q => q.UserId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(q => q.Provider)
             .WithMany(p => p.QueueTokens)
             .HasForeignKey(q => q.ProviderId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(q => q.Service)
             .WithMany(s => s.QueueTokens)
             .HasForeignKey(q => q.ServiceId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(q => q.Counter)
             .WithMany()
             .HasForeignKey(q => q.CounterId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── ServiceCounter ──
        modelBuilder.Entity<ServiceCounter>(e =>
        {
            e.Property(c => c.Status).HasConversion<string>().HasMaxLength(20);

            e.HasOne(c => c.Provider)
             .WithMany(p => p.Counters)
             .HasForeignKey(c => c.ProviderId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(c => c.StaffUser)
             .WithMany()
             .HasForeignKey(c => c.StaffUserId)
             .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(c => c.ActiveToken)
             .WithMany()
             .HasForeignKey(c => c.ActiveTokenId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── Notification ──
        modelBuilder.Entity<Notification>(e =>
        {
            e.Property(n => n.Type).HasConversion<string>().HasMaxLength(20);

            e.HasOne(n => n.User)
             .WithMany(u => u.Notifications)
             .HasForeignKey(n => n.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── ActivityLog ──
        modelBuilder.Entity<ActivityLog>(e =>
        {
            e.HasOne(a => a.Provider)
             .WithMany(p => p.ActivityLogs)
             .HasForeignKey(a => a.ProviderId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(a => a.User)
             .WithMany()
             .HasForeignKey(a => a.UserId)
             .OnDelete(DeleteBehavior.SetNull);
        });
    }
}
