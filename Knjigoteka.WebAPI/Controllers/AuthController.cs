using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;

    public AuthController(IAuthService auth) => _auth = auth;

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
}
