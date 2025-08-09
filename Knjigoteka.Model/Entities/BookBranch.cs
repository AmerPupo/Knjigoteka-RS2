namespace Knjigoteka.Model.Entities
{
    public class BookBranch
    {
        public int BookId { get; set; }
        public int BranchId { get; set; }
        public int QuantityForBorrow { get; set; }
        public int QuantityForSale { get; set; }

        public Book Book { get; set; } = null!;
        public Branch Branch { get; set; } = null!;
    }
}
