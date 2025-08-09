namespace Knjigoteka.Model.Entities
{
    public class Reservation
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public int UserId { get; set; }
        public int BranchId { get; set; }
        public DateTime ReservedAt { get; set; }
        public DateTime? ConfirmedAt { get; set; }
        public DateTime? ExpiredAt { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Confirmed, Expired

        public Book Book { get; set; } = null!;
        public User User { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
    }
}
