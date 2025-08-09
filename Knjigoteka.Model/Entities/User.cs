namespace Knjigoteka.Model.Entities
{
    public class User
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string PasswordHash { get; set; } = null!;
        public int RoleId { get; set; }
        public bool IsBlocked { get; set; } = false;

        public Role Role { get; set; } = null!;
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Borrowing> Borrowings { get; set; } = new List<Borrowing>();
        public ICollection<Order> Orders { get; set; } = new List<Order>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<Penalty> Penalties { get; set; } = new List<Penalty>();
    }
}

