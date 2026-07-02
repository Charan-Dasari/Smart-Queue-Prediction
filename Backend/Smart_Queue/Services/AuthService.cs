using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Smart_Queue.Data;
using Smart_Queue.DTOs;
using Smart_Queue.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Smart_Queue.Services;

public class AuthService
{
    private readonly SmartQueueDbContext _db;
    private readonly IConfiguration _config;

    public AuthService(SmartQueueDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request)
    {
        var identifier = request.Identifier.Trim();
        var user = await _db.Users
            .Include(u => u.Provider)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == identifier.ToLower() || u.Mobile == identifier);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return null;

        return new AuthResponse
        {
            Token = GenerateToken(user),
            User = MapToDto(user)
        };
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
    {
        if (await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower()))
            return null; // Email already exists

        var user = new User
        {
            Name = request.Name,
            Email = request.Email,
            Mobile = request.Mobile,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRole.User,
            ProviderId = null
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return new AuthResponse
        {
            Token = GenerateToken(user),
            User = MapToDto(user)
        };
    }

    public async Task<UserDto?> GetProfileAsync(Guid userId)
    {
        var user = await _db.Users
            .Include(u => u.Provider)
            .FirstOrDefaultAsync(u => u.Id == userId);

        return user == null ? null : MapToDto(user);
    }

    public async Task<UserDto?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
    {
        var user = await _db.Users
            .Include(u => u.Provider)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return null;

        if (request.Name != null) user.Name = request.Name;
        if (request.Mobile != null) user.Mobile = request.Mobile;
        if (request.Email != null)
        {
            // Check uniqueness
            if (await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower() && u.Id != userId))
                return null;
            user.Email = request.Email;
        }

        await _db.SaveChangesAsync();
        return MapToDto(user);
    }

    public async Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return false;

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
            return false;

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ResetPasswordVerifyAsync(ResetPasswordVerifyRequest request)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => 
            u.Email.ToLower() == request.Email.ToLower() && 
            u.Mobile == request.Mobile && 
            u.Name.ToLower() == request.Name.ToLower());
        
        if (user == null) return false;

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _db.SaveChangesAsync();
        return true;
    }

    private string GenerateToken(User user)
    {
        var jwtConfig = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtConfig["Key"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Name),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim("ProviderId", user.ProviderId?.ToString() ?? ""),
        };

        var token = new JwtSecurityToken(
            issuer: jwtConfig["Issuer"],
            audience: jwtConfig["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(double.Parse(jwtConfig["ExpiresInMinutes"]!)),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public static UserDto MapToDto(User user) => new()
    {
        Id = user.Id,
        Name = user.Name,
        Email = user.Email,
        Mobile = user.Mobile,
        Role = user.Role,
        ProviderId = user.ProviderId,
        ProviderName = user.Provider?.Name
    };
}
