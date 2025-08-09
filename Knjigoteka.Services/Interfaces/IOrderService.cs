using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IOrderService
    {
        Task<OrderResponse> CheckoutAsync(OrderCreate dto);
        Task<List<OrderResponse>> GetMyOrdersAsync();
        Task<List<OrderResponse>> GetAllAsync();
    }
}
