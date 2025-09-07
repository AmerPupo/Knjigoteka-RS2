using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Knjigoteka.Services.Services
{
    public class ReservationService
        : BaseCRUDService<ReservationResponse, ReservationSearchObject, ReservationRequest, ReservationRequest, Reservation>, IReservationService
    {
        private readonly IUserContext _userContext;
        private readonly DatabaseContext _context;
        private readonly IPenaltyService _penaltyService;
        private readonly IUserService _userService;
        private readonly ILogger<ReservationService> _logger;
        public ReservationService(
               DatabaseContext context,
               IUserContext userContext,
               IPenaltyService penaltyService,
               IUserService userService,
               ILogger<ReservationService> logger)
               : base(context)
        {
            _context = context;
            _userContext = userContext;
            _penaltyService = penaltyService;
            _userService = userService;
            _logger = logger;
        }

        protected override IQueryable<Reservation> AddInclude(IQueryable<Reservation> query)
        {
            return query
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .Include(r => r.User);
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject? search)
        {
            if (search == null) return query;

            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if(!string.IsNullOrWhiteSpace(search.UserName))
                query = query.Where(r => r.User.FirstName.ToLower().StartsWith(search.UserName.ToLower()) || r.User.LastName.ToLower().StartsWith(search.UserName.ToLower()));

            if (search.BranchId.HasValue)
                query = query.Where(r => r.BranchId == search.BranchId.Value);

            if (!string.IsNullOrWhiteSpace(search.Status))
                query = query.Where(r => r.Status.ToString() == search.Status);

            if (search.ActiveOnly)
                query = query.Where(r =>
                    r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Claimed);

            query = query
       .OrderBy(r => r.Status == ReservationStatus.Pending ? 0 : 1)
       .ThenByDescending(r => r.ReservedAt);
            return query;
        }

        public override async Task<ReservationResponse> Insert(ReservationRequest request)
        {
            var userId = _userContext.UserId;

            var existing = await _context.Reservations.AnyAsync(r =>
                r.UserId == userId &&
                r.BookId == request.BookId &&
                r.Status == ReservationStatus.Pending);

            if (existing)
                throw new InvalidOperationException("Već imate aktivnu rezervaciju za ovu knjigu.");

            var entity = new Reservation
            {
                BookId = request.BookId,
                BranchId = request.BranchId,
                ReservedAt = DateTime.Now,
                Status = ReservationStatus.Pending,
                UserId = userId
            };

            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            var full = await _context.Reservations
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .Include(r => r.User)
                .FirstAsync(r => r.Id == entity.Id);

            return MapToDto(full);
        }

        public async Task<bool> Confirm(int reservationId)
        {
            var entity = await _context.Reservations.FindAsync(reservationId)
                ?? throw new KeyNotFoundException("Rezervacija nije pronađena.");

            if (entity.Status != ReservationStatus.Pending)
                throw new InvalidOperationException("Rezervaciju je moguće potvrditi samo ako je status 'Pending'.");

            entity.Status = ReservationStatus.Claimed;
            entity.ClaimedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> Return(int reservationId)
        {
            var entity = await _context.Reservations.FindAsync(reservationId)
                ?? throw new KeyNotFoundException("Rezervacija nije pronađena.");

            if (entity.Status != ReservationStatus.Claimed)
                throw new InvalidOperationException("Povrat je moguć samo ako je rezervacija prethodno preuzeta.");

            entity.Status = ReservationStatus.Returned;
            entity.ReturnedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return true;
        }
        public async Task<int> ExpirePendingReservationsAsync()
        {
            var now = DateTime.UtcNow;
            var toExpire = await _context.Reservations
                .Where(r => r.Status == ReservationStatus.Pending && r.ExpiredAt != null && r.ExpiredAt < now)
                .ToListAsync();

            if (!toExpire.Any()) return 0;

            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                foreach (var r in toExpire)
                {
                    r.Status = ReservationStatus.Expired;
                    r.ExpiredAt = r.ExpiredAt ?? now;

                    await _penaltyService.AddAsync(r.UserId, "Unclaimed reservation");

                    await _userService.BlockIfExceededPenaltyThreshold(r.UserId);
                }

                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                _logger.LogInformation("Expired {Count} reservations.", toExpire.Count);
                return toExpire.Count;
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Error while expiring reservations.");
                throw;
            }
        }
        protected override ReservationResponse MapToDto(Reservation entity)
        {
            return new ReservationResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User.FirstName + " " + entity.User.LastName,
                BookId = entity.BookId,
                BookTitle = entity.Book?.Title ?? "",
                BranchId = entity.BranchId,
                BranchName = entity.Branch?.Name ?? "",
                ReservedAt = entity.ReservedAt,
                ClaimedAt = entity.ClaimedAt,
                ReturnedAt = entity.ReturnedAt,
                ExpiredAt = entity.ExpiredAt,
                Status = entity.Status.ToString()
            };
        }

        protected override Reservation MapToEntity(ReservationRequest request)
        {
            return new Reservation
            {
                BookId = request.BookId,
                BranchId = request.BranchId,
                ReservedAt = DateTime.Now,
                Status = ReservationStatus.Pending,
                UserId = _userContext.UserId
            };
        }

        protected override void MapToEntity(ReservationRequest request, Reservation entity)
        {

        }
    }
}
