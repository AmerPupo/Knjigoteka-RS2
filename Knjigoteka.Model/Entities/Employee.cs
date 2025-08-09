namespace Knjigoteka.Model.Entities
{
    public class Employee
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BranchId { get; set; }
        public DateTime EmploymentDate { get; set; }

        public User User { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
    }
}
