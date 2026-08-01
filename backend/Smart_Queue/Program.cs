using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Smart_Queue.Data;
using Smart_Queue.Services;
using System.Text;
using Scalar.AspNetCore;


var builder = WebApplication.CreateBuilder(args);

// ── Database ──
builder.Services.AddDbContext<SmartQueueDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"), 
        sqlServerOptionsAction: sqlOptions =>
        {
            sqlOptions.CommandTimeout(120);
        }));

// ── JWT Authentication ──
var jwtConfig = builder.Configuration.GetSection("Jwt");
var jwtKey = Encoding.UTF8.GetBytes(jwtConfig["Key"]!);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtConfig["Issuer"],
        ValidAudience = jwtConfig["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(jwtKey),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// ── Services (DI) ──
builder.Services.AddScoped<AuthService>();
builder.Services.AddMemoryCache();
builder.Services.AddScoped<QueueService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<ProviderService>();

// Register ML Prediction Service with HttpClient
builder.Services.AddHttpClient<MlPredictionService>(client =>
{
    var mlBaseUrl = builder.Configuration["MlApi:BaseUrl"] ?? "http://127.0.0.1:8000";
    client.BaseAddress = new Uri(mlBaseUrl);
});

// ── Controllers ──
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

// ── CORS (allow Flutter web/mobile during development) ──
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// ── OpenAPI ──
builder.Services.AddOpenApi();

var app = builder.Build();

// ── Seed Database ──
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<SmartQueueDbContext>();
    await db.Database.MigrateAsync();
    await DbSeeder.SeedAsync(db); // Seed test users + providers synchronously

    // Import CSV datasets into Places table asynchronously in background so app starts immediately
    var datasetsFolder = Path.Combine(AppContext.BaseDirectory, "Datasets_Clean");
    if (Directory.Exists(datasetsFolder))
    {
        _ = Task.Run(async () =>
        {
            using var bgScope = app.Services.CreateScope();
            var bgDb = bgScope.ServiceProvider.GetRequiredService<SmartQueueDbContext>();
            await PlaceSeeder.SeedPlacesAsync(bgDb, datasetsFolder);
        });
    }
    else
    {
        Console.WriteLine($"[PlaceSeeder] Datasets folder not found at: {datasetsFolder}");
    }
}

// ── Middleware Pipeline ──
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("IntelliQ API");
        options.WithTheme(Scalar.AspNetCore.ScalarTheme.DeepSpace);
    });
}

app.UseCors("AllowFlutter");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
