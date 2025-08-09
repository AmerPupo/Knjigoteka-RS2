using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GenresController
        : BaseCRUDController<GenreResponse, GenreSearchObject, GenreInsert, GenreUpdate>
    {
        public GenresController(
            ILogger<BaseController<GenreResponse, GenreSearchObject>> logger,
            ICRUDService<GenreResponse, GenreSearchObject, GenreInsert, GenreUpdate> service)
            : base(logger, service)
        { }
    }
}
