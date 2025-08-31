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
    public class LanguagesController
        : BaseCRUDController<LanguageResponse, LanguageSearchObject, LanguageInsert, LanguageUpdate>
    {
        public LanguagesController(
            ILogger<BaseController<LanguageResponse, LanguageSearchObject>> logger,
            ILanguageService service)
            : base(logger, service)
        {
        }
    }
}
