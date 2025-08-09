using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class OrderService : IOrderService
    {
        private readonly DatabaseContext _db;
        private readonly IUserContext _user;

        public OrderService(DatabaseContext db, IUserContext user)
        {
            _db = db;
            _user = user;
        }

        public async Task<OrderResponse> CheckoutAsync(OrderCreate dto)
        {
            var cart = await _db.CartItems
                .Include(ci => ci.Book)
                .Where(ci => ci.UserId == _user.UserId)
                .ToListAsync();

            if (cart.Count == 0)
                throw new InvalidOperationException("Cart is empty.");

            foreach (var ci in cart)
            {
                if (ci.Quantity <= 0) throw new InvalidOperationException("Invalid quantity in cart.");
                if (ci.Book.TotalQuantity < ci.Quantity)
                    throw new InvalidOperationException($"Not enough stock for '{ci.Book.Title}'.");
            }

            var total = cart.Sum(i => i.Book.Price * i.Quantity);

            var order = new Order
            {
                UserId = _user.UserId,
                OrderDate = DateTime.UtcNow,
                Status = "Pending",
                PaymentMethod = dto.PaymentMethod,
                DeliveryAddress = dto.DeliveryAddress,
                TotalAmount = total
            };

            _db.Orders.Add(order);
            await _db.SaveChangesAsync();

            foreach (var ci in cart)
            {
                _db.OrderItems.Add(new OrderItem
                {
                    OrderId = order.Id,
                    BookId = ci.BookId,
                    Quantity = ci.Quantity,
                    UnitPrice = ci.Book.Price // snapshot price
                });

                ci.Book.TotalQuantity -= ci.Quantity;
            }

            _db.CartItems.RemoveRange(cart);
            await _db.SaveChangesAsync();

            return new OrderResponse
            {
                Id = order.Id,
                CreatedAt = order.OrderDate,   // <- map from OrderDate
                Status = order.Status,
                PaymentMethod = order.PaymentMethod,
                TotalAmount = order.TotalAmount,
                Items = cart.Select(ci => new OrderItemResponse
                {
                    BookId = ci.BookId,
                    Title = ci.Book.Title,
                    Quantity = ci.Quantity,
                    UnitPrice = ci.Book.Price
                }).ToList()
            };
        }

        private static OrderResponse MapOrder(Order o) => new()
        {
            Id = o.Id,
            CreatedAt = o.OrderDate,          // <- map from OrderDate
            Status = o.Status,
            PaymentMethod = o.PaymentMethod,
            TotalAmount = o.TotalAmount,
            Items = o.OrderItems.Select(oi => new OrderItemResponse
            {
                BookId = oi.BookId,
                Title = oi.Book.Title,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice
            }).ToList()
        };

        public async Task<List<OrderResponse>> GetMyOrdersAsync()
        {
            var orders = await _db.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book)
                .Where(o => o.UserId == _user.UserId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders.Select(MapOrder).ToList();
        }

        public async Task<List<OrderResponse>> GetAllAsync()
        {
            var orders = await _db.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders.Select(MapOrder).ToList();
        }

    }
}
