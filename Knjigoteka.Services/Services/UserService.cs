using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

public class UserService : IUserService
{
    private readonly DatabaseContext _context;
    private readonly IConfiguration _config;
    private IPenaltyService _penaltyService;

    public UserService(DatabaseContext context, IConfiguration config, IPenaltyService ps)
    {
        _context = context;
        _config = config;
        _penaltyService = ps;
    }

    public async Task RegisterAsync(RegisterRequest dto)
    {
        if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
            throw new Exception("Email already in use.");

        var hasher = new PasswordHasher<User>();
        var user = new User
        {
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email,
            RoleId = 3 
        };
        user.PasswordHash = hasher.HashPassword(user, dto.Password);

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
    }

    public async Task<LoginResponse> LoginAsync(LoginRequest dto)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Email == dto.Email);

        if (user == null)
            throw new Exception("Invalid credentials.");

        var hasher = new PasswordHasher<User>();
        var result = hasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
        if (result == PasswordVerificationResult.Failed)
            throw new Exception("Invalid credentials.");

        // Create claims
        var claims = new List<Claim>
    {
      new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
      new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
      new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
      new Claim(ClaimTypes.Email, user.Email),
      new Claim(ClaimTypes.Role, user.Role.Name),
      new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

        // Get settings
        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var expires = DateTime.UtcNow.AddMinutes(double.Parse(jwt["ExpireMinutes"]!));

        // Create token
        var token = new JwtSecurityToken(
          issuer: jwt["Issuer"],
          audience: jwt["Audience"],
          claims: claims,
          expires: expires,
          signingCredentials: creds
        );

        return new LoginResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            Expires = expires
        };
    }
    public async Task<bool> IsUserBlocked(int userId)
    {
        var points = await _penaltyService.GetPointsAsync(userId);
        return points >= 3;
    }
    public async Task BlockIfExceededPenaltyThreshold(int userId)
    {
        var count = await _context.Penalties.CountAsync(p => p.UserId == userId);
        if (count >= 3)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user != null && !user.IsBlocked)
            {
                user.IsBlocked = true;
                await _context.SaveChangesAsync();
            }
        }
    }

}