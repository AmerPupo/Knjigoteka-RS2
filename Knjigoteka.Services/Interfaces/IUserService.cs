using Knjigoteka.Model.Responses;
using Knjigoteka.Model.Requests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IUserService
    {
        Task RegisterAsync(RegisterRequest dto);
        Task<LoginResponse> LoginAsync(LoginRequest dto);
    }

}
