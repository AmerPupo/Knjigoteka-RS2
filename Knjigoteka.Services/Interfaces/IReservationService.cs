using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;

namespace Knjigoteka.Services.Interfaces
{
    public interface IReservationService 
        : ICRUDService<ReservationResponse, ReservationSearchObject, ReservationRequest, ReservationRequest>
    {
        Task<bool> Confirm(int reservationId);
        Task<bool> Return(int reservationId);
        Task<int> ExpirePendingReservationsAsync();
    }
}
