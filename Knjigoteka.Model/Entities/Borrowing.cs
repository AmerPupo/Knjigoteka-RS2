namespace Knjigoteka.Model.Entities
{
    public class Borrowing
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public int UserId { get; set; }
        public int BranchId { get; set; }
        public DateTime BorrowedAt { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime? ReturnedAt { get; set; }
        public bool IsLate => ReturnedAt.HasValue && ReturnedAt.Value > DueDate;

        public Book Book { get; set; } = null!;
        public User User { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
    }
}
