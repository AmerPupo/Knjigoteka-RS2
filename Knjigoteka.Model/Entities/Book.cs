using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Model.Entities
{
    public class Book
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Author { get; set; } = null!;
        public int GenreId { get; set; }
        public int LanguageId { get; set; }
        public string ISBN { get; set; } = null!;
        public int Year { get; set; }
        public int TotalQuantity { get; set; }
        public string ShortDescription { get; set; } = null!;
        [Precision(18, 2)]
        public decimal Price { get; set; }
        public string PhotoUrl { get; set; } = null!;
        public Genre Genre { get; set; } = null!;
        public Language Language { get; set; } = null!;
        public ICollection<BookBranch> BookBranches { get; set; } = new List<BookBranch>();
    }
}
