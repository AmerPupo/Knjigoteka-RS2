namespace Knjigoteka.Model.Entities
{
    public class RestockRequest
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public int BranchId { get; set; }
        public int EmployeeId { get; set; }
        public int QuantityRequested { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Approved, Rejected

        public Book Book { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
        public Employee Employee { get; set; } = null!;
    }
}
