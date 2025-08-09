using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Status { get; set; } = null!; // Pending, Approved, Shipped, Canceled...
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = null!;
        public List<OrderItemResponse> Items { get; set; } = new();
    }
}
