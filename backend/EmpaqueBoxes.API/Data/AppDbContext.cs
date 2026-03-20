using EmpaqueBoxes.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EmpaqueBoxes.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Box> Boxes => Set<Box>();
    public DbSet<Towel> Towels => Set<Towel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Box>(e =>
        {
            e.HasKey(b => b.BoxId);
            e.Property(b => b.BoxCode).IsRequired().HasMaxLength(50);
            e.Property(b => b.ProductCode).IsRequired().HasMaxLength(50);
            e.Property(b => b.Status).IsRequired().HasMaxLength(10).HasDefaultValue("OPEN");
            e.Property(b => b.IsActive).HasDefaultValue(true);
            e.HasIndex(b => b.BoxCode).IsUnique().HasFilter("[IsActive] = 1");
        });

        modelBuilder.Entity<Towel>(e =>
        {
            e.HasKey(t => t.TowelId);
            e.Property(t => t.ItemCode).IsRequired().HasMaxLength(50);
            e.Property(t => t.ProductCode).IsRequired().HasMaxLength(50);
            e.Property(t => t.Status).IsRequired().HasMaxLength(10).HasDefaultValue("LOOSE");
            e.Property(t => t.IsActive).HasDefaultValue(true);
            e.HasIndex(t => t.ItemCode).IsUnique().HasFilter("[IsActive] = 1");
            e.HasOne(t => t.Box)
             .WithMany(b => b.Towels)
             .HasForeignKey(t => t.BoxId)
             .IsRequired(false);
        });
    }
}
