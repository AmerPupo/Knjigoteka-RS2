using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Model.Entities
{
    public class OrderItem
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int BookId { get; set; }
        public int Quantity { get; set; }
        [Precision(18, 2)]
        public decimal UnitPrice { get; set; }

        public Book Book { get; set; } = null!;
        public Order Order { get; set; } = null!;
    }
}
