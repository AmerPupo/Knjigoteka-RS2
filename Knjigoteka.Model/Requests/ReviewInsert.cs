﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class ReviewInsert
    {
        public int BookId { get; set; }
        public int Rating { get; set; } // 1-5
        public string? Comment { get; set; }
    }
}
