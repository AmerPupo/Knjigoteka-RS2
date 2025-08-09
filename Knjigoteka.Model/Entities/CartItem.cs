namespace Knjigoteka.Model.Entities
{
    public class CartItem
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BookId { get; set; }
        public int Quantity { get; set; }
        public DateTime AddedAt { get; set; }

        public User User { get; set; } = null!;
        public Book Book { get; set; } = null!;
    }
}
