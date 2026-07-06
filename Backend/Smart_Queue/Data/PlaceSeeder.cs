using Microsoft.EntityFrameworkCore;
using Smart_Queue.Models;

namespace Smart_Queue.Data;

public static class PlaceSeeder
{
    /// <summary>
    /// Import CSV datasets into the Places table. Skips if data already exists.
    /// Expected CSV formats:
    ///   Hospitals: Name,Category,State,City,Address
    ///   Banks:     Name,Category,State,City,Address
    ///   Restaurants: Name,Category,State,City,Rating
    ///   Colleges:  Name,Category,State,City
    /// </summary>
    public static async Task SeedPlacesAsync(SmartQueueDbContext db, string datasetsFolder)
    {
        if (await db.Places.AnyAsync())
        {
            Console.WriteLine("[PlaceSeeder] Places table already has data. Skipping import.");
            return;
        }

        Console.WriteLine("[PlaceSeeder] Starting CSV import...");

        var files = new[]
        {
            ("Hospitals_Clean.csv", "Hospital"),
            ("Banks_Clean.csv", "Bank"),
            ("Restaurants_Clean.csv", "Restaurant"),
            ("Colleges_Clean.csv", "College"),
        };

        int totalImported = 0;

        foreach (var (fileName, category) in files)
        {
            var filePath = Path.Combine(datasetsFolder, fileName);
            if (!File.Exists(filePath))
            {
                Console.WriteLine($"[PlaceSeeder] File not found: {filePath}. Skipping.");
                continue;
            }

            Console.WriteLine($"[PlaceSeeder] Importing {fileName}...");

            var places = new List<Place>();
            var lines = await File.ReadAllLinesAsync(filePath);

            // Skip header row
            for (int i = 1; i < lines.Length; i++)
            {
                var line = lines[i];
                if (string.IsNullOrWhiteSpace(line)) continue;

                var fields = ParseCsvLine(line);
                if (fields.Count < 3) continue; // Need at least Name, Category/State, City

                var place = new Place
                {
                    Category = category,
                };

                switch (category)
                {
                    case "Hospital":
                    case "Bank":
                        // Format: Name,Category,State,City,Address
                        if (fields.Count >= 4)
                        {
                            place.Name = fields[0].Trim();
                            place.State = fields[2].Trim();
                            place.City = fields[3].Trim();
                            place.Address = fields.Count >= 5 ? fields[4].Trim() : "";
                        }
                        break;

                    case "Restaurant":
                        // Format: Name,Category,State,City,Rating
                        if (fields.Count >= 4)
                        {
                            place.Name = fields[0].Trim();
                            place.State = fields[2].Trim();
                            place.City = fields[3].Trim();
                            if (fields.Count >= 5 && double.TryParse(fields[4].Trim(), out var rating))
                                place.Rating = rating;
                        }
                        break;

                    case "College":
                        // Format: Name,Category,State,City
                        if (fields.Count >= 4)
                        {
                            place.Name = fields[0].Trim();
                            place.State = fields[2].Trim();
                            place.City = fields[3].Trim();
                        }
                        break;
                }

                if (!string.IsNullOrEmpty(place.Name))
                {
                    places.Add(place);
                }
            }

            // Batch insert for performance
            const int batchSize = 5000;
            for (int j = 0; j < places.Count; j += batchSize)
            {
                var batch = places.Skip(j).Take(batchSize).ToList();
                db.Places.AddRange(batch);
                await db.SaveChangesAsync();
                // Detach to free memory
                foreach (var entity in batch)
                {
                    db.Entry(entity).State = EntityState.Detached;
                }
            }

            Console.WriteLine($"[PlaceSeeder] Imported {places.Count} records from {fileName}.");
            totalImported += places.Count;
        }

        Console.WriteLine($"[PlaceSeeder] Done. Total records imported: {totalImported}");
    }

    /// <summary>
    /// Parse a CSV line respecting quoted fields with commas inside them.
    /// </summary>
    private static List<string> ParseCsvLine(string line)
    {
        var fields = new List<string>();
        bool inQuotes = false;
        var current = new System.Text.StringBuilder();

        for (int i = 0; i < line.Length; i++)
        {
            char c = line[i];

            if (c == '"')
            {
                if (inQuotes && i + 1 < line.Length && line[i + 1] == '"')
                {
                    current.Append('"');
                    i++; // Skip escaped quote
                }
                else
                {
                    inQuotes = !inQuotes;
                }
            }
            else if (c == ',' && !inQuotes)
            {
                fields.Add(current.ToString());
                current.Clear();
            }
            else
            {
                current.Append(c);
            }
        }

        fields.Add(current.ToString());
        return fields;
    }
}
