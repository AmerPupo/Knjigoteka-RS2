namespace Knjigoteka.Model.Entities
{
    public class Branch
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Address { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string WorkingHours { get; set; } = null!;

        public ICollection<BookBranch> BookBranches { get; set; } = new List<BookBranch>();
        public ICollection<Employee> Employees { get; set; } = new List<Employee>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<RestockRequest> RestockRequests { get; set; } = new List<RestockRequest>();

    }
}