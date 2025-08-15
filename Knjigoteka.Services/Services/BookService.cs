using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BookService
        : BaseCRUDService<BookResponse, BookSearchObject, BookInsert, BookUpdate, Book>, IBookService
    {
        protected readonly DatabaseContext _context;
        public BookService(DatabaseContext context) : base(context) { _context = context; }

        protected override IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(b => b.Title.Contains(search.FTS) ||
                    b.Author.Contains(search.FTS));
            }
            if (search.GenreId.HasValue)
            {
                query = query.Where(b => b.GenreId == search.GenreId.Value);
            }

            if (search.LanguageId.HasValue)
            {
                query = query.Where(b => b.LanguageId == search.LanguageId.Value);
            }

            return query;
        }
        public override async Task<BookResponse> GetById(int id)
        {
            var entity = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new KeyNotFoundException("Book not found.");

            return MapToDto(entity);
        }
        protected override IQueryable<Book> AddInclude(IQueryable<Book> query)
        {
            return query
                .Include(b => b.Genre)
                .Include(b => b.Language);
        }
        public override async Task<BookResponse> Update(int id, BookUpdate request)
        {
            var entity = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new Exception("Book not found.");

            MapToEntity(request, entity);
            await _context.SaveChangesAsync();
            await _context.Entry(entity).Reference(b => b.Genre).LoadAsync();
            await _context.Entry(entity).Reference(b => b.Language).LoadAsync();
            return MapToDto(entity);
        }
        public override async Task<BookResponse> Insert(BookInsert request)
        {
            var entity = MapToEntity(request);
            await _context.Set<Book>().AddAsync(entity);
            await _context.SaveChangesAsync();

            var reloaded = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .FirstOrDefaultAsync(b => b.Id == entity.Id);

            return MapToDto(reloaded!);
        }

        protected override BookResponse MapToDto(Book e)
        {
            return new BookResponse
            {
                Id = e.Id,
                Title = e.Title,
                Author = e.Author,
                GenreId = e.GenreId,
                GenreName = e.Genre.Name,
                LanguageId = e.LanguageId,
                LanguageName = e.Language.Name,
                ISBN = e.ISBN,
                Year = e.Year,
                TotalQuantity = e.TotalQuantity,
                ShortDescription = e.ShortDescription,
                Price = e.Price,
                HasImage = e.BookImage != null && e.BookImage.Length > 0,
                PhotoEndpoint = $"/api/books/{e.Id}/photo"
            };
        }

        protected override Book MapToEntity(BookInsert request)
        {
            return new Book
            {
                Title = request.Title,
                Author = request.Author,
                GenreId = request.GenreId,
                LanguageId = request.LanguageId,
                ISBN = request.ISBN,
                Year = request.Year,
                TotalQuantity = request.TotalQuantity,
                ShortDescription = request.ShortDescription,
                Price = request.Price,
                BookImage = request.BookImage
            };
        }
        protected override void MapToEntity(BookUpdate request, Book entity)
        {
            entity.Title = request.Title;
            entity.Author = request.Author;
            entity.GenreId = request.GenreId;
            entity.LanguageId = request.LanguageId;
            entity.ISBN = request.ISBN;
            entity.Year = request.Year;
            entity.TotalQuantity = request.TotalQuantity;
            entity.ShortDescription = request.ShortDescription;
            entity.Price = request.Price;
            if (request.BookImage != null && request.BookImage.Length > 0)
                entity.BookImage = request.BookImage;
        }
    }
}
