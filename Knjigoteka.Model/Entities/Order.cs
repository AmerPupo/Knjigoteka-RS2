using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Model.Entities
{
    public class Order
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime OrderDate { get; set; }
        [Precision(18, 2)]
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = null!; // e.g. "CashOnDelivery", "Stripe"
        public string DeliveryAddress { get; set; } = null!;
        public string Status { get; set; } = "Pending";

        public User User { get; set; } = null!;
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
