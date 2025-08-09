using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Entities
{
    public class Payment
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public Order Order { get; set; } = null!;

        public string Method { get; set; } = null!; // e.g. Stripe, Cash
        [Precision(18, 2)]
        public decimal Amount { get; set; }
        public DateTime PaidAt { get; set; }
        public string Status { get; set; } = "Pending"; // Optional: Paid, Failed
    }
}
