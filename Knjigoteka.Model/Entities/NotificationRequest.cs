namespace Knjigoteka.Model.Entities
{
    public class NotificationRequest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BookId { get; set; }
        public int BranchId { get; set; }
        public DateTime RequestedAt { get; set; }

        public User User { get; set; } = null!;
        public Book Book { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
    }
}
