using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class Order
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public DateTime OrderDate { get; set; } = DateTime.Now;
        [Precision(18, 2)]
        public decimal TotalAmount { get; set; }
        [Required]
        public string PaymentMethod { get; set; } = null!; // e.g. "CashOnDelivery", "Stripe"
        [Required]
        public string DeliveryAddress { get; set; } = null!;
        [Required]
        public string Status { get; set; } = "Pending";

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
