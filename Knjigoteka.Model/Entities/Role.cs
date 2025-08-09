namespace Knjigoteka.Model.Entities
{
    public class Role
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!; // Admin, Employee, User

        public ICollection<User> Users { get; set; } = new List<User>();
    }
}
