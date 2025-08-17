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
        public DateTime? ClaimedAt { get; set; }
        public DateTime? ReturnedAt { get; set; }
        public DateTime? ExpiredAt { get; set; }
        [Required]
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        [ForeignKey(nameof(BranchId))]
        public Branch Branch { get; set; } = null!;
    }
    public enum ReservationStatus
    {
        Pending,
        Claimed,
        Returned,
        Expired
    }
}
