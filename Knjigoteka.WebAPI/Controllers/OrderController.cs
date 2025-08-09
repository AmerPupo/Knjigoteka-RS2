using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly IOrderService _service;
        public OrderController(IOrderService service) => _service = service;

        [Authorize(Roles = "User,Admin,Employee")]
        [HttpPost("checkout")]
        public Task<OrderResponse> Checkout(OrderCreate dto) => _service.CheckoutAsync(dto);

        [Authorize(Roles = "User,Admin,Employee")]
        [HttpGet("mine")]
        public Task<List<OrderResponse>> MyOrders() => _service.GetMyOrdersAsync();

        [Authorize(Roles = "Admin")]
        [HttpGet]
        public Task<List<OrderResponse>> All() => _service.GetAllAsync();
    }
}
