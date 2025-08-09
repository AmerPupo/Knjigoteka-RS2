using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BranchService
        : BaseCRUDService<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate, Branch>
    {
        public BranchService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Branch> ApplyFilter(IQueryable<Branch> query, BranchSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(b => EF.Functions.Like(b.Name, $"%{search.Name}%"));

            return query;
        }

        protected override BranchResponse MapToDto(Branch entity) => new()
        {
            Id = entity.Id,
            Name = entity.Name,
            Address = entity.Address,
            PhoneNumber = entity.PhoneNumber,
            WorkingHours = entity.WorkingHours
        };

        protected override Branch MapToEntity(BranchInsert request) => new()
        {
            Name = request.Name,
            Address = request.Address,
            PhoneNumber = request.PhoneNumber,
            WorkingHours = request.WorkingHours
        };

        protected override void MapToEntity(BranchUpdate request, Branch entity)
        {
            entity.Name = request.Name;
            entity.Address = request.Address;
            entity.PhoneNumber = request.PhoneNumber;
            entity.WorkingHours = request.WorkingHours;
        }
    }
}
