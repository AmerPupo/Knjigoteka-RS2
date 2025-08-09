using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class BranchInventorySearchObject : BaseSearchObject
    {
        // Full-Text Search across book fields
        public string? FTS { get; set; }

        // Facets
        public int? GenreId { get; set; }
        public int? LanguageId { get; set; }
    }
}
