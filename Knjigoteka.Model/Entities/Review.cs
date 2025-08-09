namespace Knjigoteka.Model.Entities
{
    public class Review
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public int UserId { get; set; }
        public int Rating { get; set; } // 1–5
        public string Comment { get; set; } = null!;
        public DateTime CreatedAt { get; set; }

        public Book Book { get; set; } = null!;
        public User User { get; set; } = null!;
    }
}
