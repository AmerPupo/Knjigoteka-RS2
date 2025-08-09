using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Authorize(Roles = "Admin")]
    [Route("api/[controller]")]
    public class BooksController
        : BaseCRUDController<BookResponse, BookSearchObject, BookInsert, BookUpdate>
    {
        public BooksController(
            ILogger<BaseController<BookResponse, BookSearchObject>> logger,
            ICRUDService<BookResponse, BookSearchObject, BookInsert, BookUpdate> service)
            : base(logger, service)
        { }
    }
}
