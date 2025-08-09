using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BranchInventoryService : IBranchInventoryService
    {
        private readonly DatabaseContext _db;

        public BranchInventoryService(DatabaseContext db)
        {
            _db = db;
        }

        public async Task<PagedResult<BranchInventoryResponse>> GetAsync(int branchId, BranchInventorySearchObject? search)
        {
            var q = _db.BookBranches
                .Where(bb => bb.BranchId == branchId)
                .Include(bb => bb.Book).ThenInclude(b => b.Genre)
                .Include(bb => bb.Book).ThenInclude(b => b.Language)
                .AsQueryable();

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.FTS))
                {
                    q = q.Where(bb =>
                        EF.Functions.Contains(bb.Book.Title, search.FTS!) ||
                        EF.Functions.Contains(bb.Book.Author, search.FTS!) ||
                        EF.Functions.Contains(bb.Book.ShortDescription, search.FTS!));
                }
                if (search.GenreId.HasValue)
                    q = q.Where(bb => bb.Book.GenreId == search.GenreId.Value);

                if (search.LanguageId.HasValue)
                    q = q.Where(bb => bb.Book.LanguageId == search.LanguageId.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = search?.PageSize ?? 10;
            var skip = (page - 1) * pageSize;

            var total = await q.CountAsync();

            var items = await q
                .OrderBy(bb => bb.Book.Title)
                .Skip(skip)
                .Take(pageSize)
                .Select(bb => new BranchInventoryResponse
                {
                    BookId = bb.BookId,
                    BranchId = bb.BranchId,
                    Title = bb.Book.Title,
                    Author = bb.Book.Author,
                    GenreName = bb.Book.Genre.Name,
                    LanguageName = bb.Book.Language.Name,
                    QuantityForBorrow = bb.QuantityForBorrow,
                    QuantityForSale = bb.QuantityForSale
                })
                .ToListAsync();

            return new PagedResult<BranchInventoryResponse>
            {
                Items = items,
                TotalCount = total
            };
        }

        public async Task<BranchInventoryResponse> UpsertAsync(int branchId, BranchInventoryUpsert request)
        {
            if (request.QuantityForBorrow < 0 || request.QuantityForSale < 0)
                throw new ArgumentException("Quantities must be >= 0.");

            var bb = await _db.BookBranches
                .Include(x => x.Book).ThenInclude(b => b.Genre)
                .Include(x => x.Book).ThenInclude(b => b.Language)
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == request.BookId);

            if (bb == null)
            {
                bb = new BookBranch
                {
                    BranchId = branchId,
                    BookId = request.BookId,
                    QuantityForBorrow = request.QuantityForBorrow,
                    QuantityForSale = request.QuantityForSale
                };
                _db.BookBranches.Add(bb);
            }
            else
            {
                bb.QuantityForBorrow = request.QuantityForBorrow;
                bb.QuantityForSale = request.QuantityForSale;
            }

            await _db.SaveChangesAsync();

            return new BranchInventoryResponse
            {
                BookId = bb.BookId,
                BranchId = bb.BranchId,
                Title = bb.Book.Title,
                Author = bb.Book.Author,
                GenreName = bb.Book.Genre.Name,
                LanguageName = bb.Book.Language.Name,
                QuantityForBorrow = bb.QuantityForBorrow,
                QuantityForSale = bb.QuantityForSale
            };
        }

        public async Task<bool> DeleteAsync(int branchId, int bookId)
        {
            var bb = await _db.BookBranches
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == bookId);
            if (bb == null) return false;

            _db.BookBranches.Remove(bb);
            await _db.SaveChangesAsync();
            return true;
        }
    }
}
