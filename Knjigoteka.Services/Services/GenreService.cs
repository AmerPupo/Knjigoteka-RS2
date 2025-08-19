using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace Knjigoteka.Services.Services
{
    public class GenreService
        : BaseCRUDService<GenreResponse, GenreSearchObject, GenreInsert, GenreUpdate, Genre>, IGenreService
    {
        public GenreService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Genre> ApplyFilter(IQueryable<Genre> query, GenreSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(g => g.Name.Contains(search.Name));

            return query;
        }

        protected override GenreResponse MapToDto(Genre entity)
        {
            return new GenreResponse
            {
                Id = entity.Id,
                Name = entity.Name
            };
        }

        protected override Genre MapToEntity(GenreInsert request)
        {
            return new Genre
            {
                Name = request.Name
            };
        }

        protected override void MapToEntity(GenreUpdate request, Genre entity)
        {
            entity.Name = request.Name;
        }
    }
}
