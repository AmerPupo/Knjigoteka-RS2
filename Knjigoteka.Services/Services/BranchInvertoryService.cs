using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Net;

namespace Knjigoteka.Services.Services
{
    public class BranchInventoryService :IBranchInventoryService
    {
        private readonly DatabaseContext _context;

        public BranchInventoryService(DatabaseContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<BranchInventoryResponse>> GetAsync(BranchInventorySearchObject search)
        {
            var q = _context.BookBranches
                .Include(bb => bb.Book).ThenInclude(b => b.Genre)
                .Include(bb => bb.Book).ThenInclude(b => b.Language)
                .AsQueryable();
            if (string.IsNullOrWhiteSpace(search.FTS)
                && search.BranchId <= 0
                && search.BookId <= 0)
            {
                throw new ArgumentException("At least one search parameter expected.");
            }


            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.FTS))
                {
                    q = q.Where(bb =>
                        bb.Book.Title.Contains(search.FTS) ||
                        bb.Book.Author.Contains(search.FTS));
                }
                if (search.BranchId > 0)
                    q = q.Where(bb => bb.BranchId == search.BranchId);

                if (search.BookId > 0)
                    q = q.Where(bb => bb.BookId == search.BookId);
                if (search.SupportsBorrowing.HasValue)
                    q = q.Where(bb => bb.SupportsBorrowing == search.SupportsBorrowing);
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
                    SupportsBorrowing = bb.SupportsBorrowing,
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

            var book = await _context.Books
                .Include(b => b.BookBranches)
                .FirstOrDefaultAsync(b => b.Id == request.BookId)
                ?? throw new KeyNotFoundException("Book not found.");

            int totalRequested = request.QuantityForBorrow + request.QuantityForSale;

            if (totalRequested > book.CentralStock)
                throw new InvalidOperationException("Not enough books in central stock.");

            var bb = await _context.BookBranches
                .Include(x => x.Book).ThenInclude(b => b.Genre)
                .Include(x => x.Book).ThenInclude(b => b.Language)
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == request.BookId);

            if (bb == null)
            {
                bb = new BookBranch
                {
                    BranchId = branchId,
                    BookId = request.BookId,
                    SupportsBorrowing = request.SupportsBorrowing,
                    QuantityForBorrow = request.QuantityForBorrow,
                    QuantityForSale = request.QuantityForSale
                };
                _context.BookBranches.Add(bb);
            }
            else
            {
                bb.QuantityForBorrow += request.QuantityForBorrow;
                bb.QuantityForSale += request.QuantityForSale;
            }

            book.CentralStock -= totalRequested;

            await _context.SaveChangesAsync();

            return MapToDto(bb);
        }



        public async Task<bool> DeleteAsync(int branchId, int bookId)
        {
            var bb = await _context.BookBranches
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == bookId);
            if (bb == null) return false;

            _context.BookBranches.Remove(bb);
            await _context.SaveChangesAsync();
            return true;
        }
        protected BranchInventoryResponse MapToDto(BookBranch bb)
        {
            return new BranchInventoryResponse
            {
                BookId = bb.BookId,
                BranchId = bb.BranchId,
                Title = bb.Book?.Title ?? "Nepoznat naslov",
                Author = bb.Book?.Author ?? "Nepoznat autor",
                GenreName = bb.Book?.Genre?.Name ?? "Nepoznat žanr",
                LanguageName = bb.Book?.Language?.Name ?? "Nepoznat jezik",
                SupportsBorrowing = bb.SupportsBorrowing,
                QuantityForBorrow = bb.QuantityForBorrow,
                QuantityForSale = bb.QuantityForSale
            };
        }
    }
}
