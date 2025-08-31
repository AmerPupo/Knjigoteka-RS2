using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly IUserService _auth;

    public UserController(IUserService auth) => _auth = auth;

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest dto)
    {
        await _auth.RegisterAsync(dto);
        return Ok(new { message = "Registration successful." });
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest dto)
    {
        var result = await _auth.LoginAsync(dto);
        return Ok(result);
    }
    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetCurrentUser()
    {
        return await _auth.GetCurrentUserAsync();
    }
    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<ActionResult<List<UserResponse>>> GetAll()
    {
        var users = await _auth.GetAllAsync();
        return Ok(new { items = users });
    }
}
