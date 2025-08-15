using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int BookId { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public int BranchId { get; set; }
        [Required]
        public DateTime ReservedAt { get; set; }
        [Required]
        public DateTime? ConfirmedAt { get; set; }
        [Required]
        public DateTime? ExpiredAt { get; set; }
        [Required]
        public string Status { get; set; } = "Pending"; // Pending, Confirmed, Expired

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        [ForeignKey(nameof(BranchId))]
        public Branch Branch { get; set; } = null!;
    }
}
