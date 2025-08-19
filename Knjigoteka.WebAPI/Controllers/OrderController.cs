﻿using Knjigoteka.Model.Requests;
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
        public async Task<ActionResult<OrderResponse>> Checkout([FromBody] OrderCreate dto)
        {
            try
            {
                var res = await _service.CheckoutAsync(dto);
                return CreatedAtAction(nameof(GetMyOrders), new { }, res);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [Authorize(Roles = "User,Admin,Employee")]
        [HttpGet("mine")]
        public Task<List<OrderResponse>> GetMyOrders() => _service.GetMyOrdersAsync();

        [Authorize(Roles = "Admin")]
        [HttpGet]
        public Task<List<OrderResponse>> GetAll() => _service.GetAllAsync();
    }
}
