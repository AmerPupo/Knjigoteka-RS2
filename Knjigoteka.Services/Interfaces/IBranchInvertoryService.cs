using Knjigoteka.Model;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;

namespace Knjigoteka.Services.Interfaces
{
    public interface IBranchInventoryService
    {
        Task<PagedResult<BranchInventoryResponse>> GetAsync(int branchId, BranchInventorySearchObject? search);
        Task<BranchInventoryResponse> UpsertAsync(int branchId, BranchInventoryUpsert request);
        Task<bool> DeleteAsync(int branchId, int bookId);
    }
}
