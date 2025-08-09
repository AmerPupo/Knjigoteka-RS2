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
    [Authorize(Roles = "Admin")]
    public class BranchesController
        : BaseCRUDController<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate>
    {
        public BranchesController(
            ILogger<BaseController<BranchResponse, BranchSearchObject>> logger,
            ICRUDService<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate> service)
            : base(logger, service) { }
    }
}
