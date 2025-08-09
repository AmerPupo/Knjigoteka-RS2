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
        : BaseCRUDService<BookResponse, BookSearchObject, BookInsert, BookUpdate, Book>
    {
        public BookService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(b =>
                    EF.Functions.Contains(b.Title, search.FTS) ||
                    EF.Functions.Contains(b.Author, search.FTS) ||
                    EF.Functions.Contains(b.ShortDescription, search.FTS));
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
        protected override BookResponse MapToDto(Book entity)
        {
            return new BookResponse
            {
                Id = entity.Id,
                Title = entity.Title,
                Author = entity.Author,
                GenreId = entity.GenreId,
                GenreName = entity.Genre.Name,
                LanguageId = entity.LanguageId,
                LanguageName = entity.Language.Name,
                ISBN = entity.ISBN,
                Year = entity.Year,
                TotalQuantity = entity.TotalQuantity,
                ShortDescription = entity.ShortDescription,
                Price = entity.Price,
                PhotoUrl = entity.PhotoUrl
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
                PhotoUrl = request.PhotoUrl
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
            entity.PhotoUrl = request.PhotoUrl;
        }
    }
}
