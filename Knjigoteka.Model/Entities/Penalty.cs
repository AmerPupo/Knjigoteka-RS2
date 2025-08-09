namespace Knjigoteka.Model.Entities
{
    public class Penalty
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Reason { get; set; } = null!; // e.g. "Late return", "Unclaimed reservation"
        public DateTime CreatedAt { get; set; }

        public User User { get; set; } = null!;
    }
}
