using Knjigoteka.Model.Entities;
using Knjigoteka.Services.Database;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly DatabaseContext _db;

        private const int RES_STATUS_REJECTED = 0;
        private const int RES_STATUS_CONFIRMED = 1;
        private const int RES_STATUS_PENDING = 2;
        private readonly string _webRoot;
        private readonly string _contentRoot;
       public SeedController(DatabaseContext db, IWebHostEnvironment env)
        {
            _db = db;
            _webRoot = string.IsNullOrWhiteSpace(env.WebRootPath)
                ? Path.Combine(env.ContentRootPath, "wwwroot")
                : env.WebRootPath;
            _contentRoot = env.ContentRootPath;
        }

        [HttpPost("init")]
        public async Task<IActionResult> Init()
        {
            if (!await _db.Roles.AnyAsync())
            {
                await _db.Roles.AddRangeAsync(new[]
                {
                    new Role { Name = "Admin" },
                    new Role { Name = "Employee" },
                    new Role { Name = "User" }
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Cities.AnyAsync())
            {
                await _db.Cities.AddRangeAsync(new[]
                {
                    new City { Name = "Tuzla" },
                    new City { Name = "Sarajevo" },
                    new City { Name = "Mostar" }
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Branches.AnyAsync())
            {
                var cityTuzla = await _db.Cities.FirstAsync();
                var citySa = await _db.Cities.OrderBy(x => x.Id).Skip(1).FirstAsync();
                await _db.Branches.AddRangeAsync(new[]
                {
                    new Branch { Name = "Centralna", Address = "Zlatnih ljiljana 1", CityId = cityTuzla.Id, PhoneNumber = "035-123-456" },
                    new Branch { Name = "Sarajevska", Address = "Titova 22", CityId = citySa.Id, PhoneNumber = "033-987-654" }
                });
                await _db.SaveChangesAsync();
            }

            var hasher = new PasswordHasher<User>();
            if (!await _db.Users.AnyAsync())
            {
                await _db.Users.AddRangeAsync(new[]
                {
                    MakeUser(1, "admin@knjigoteka.local", "Admin", "Glavni", "Admin123!", hasher),
                    MakeUser(2, "radnik@knjigoteka.local", "Emir", "Radnik", "Radnik123!", hasher),
                    MakeUser(3, "pupo@knjigoteka.local", "Pupo", "Korisnik", "Pupo123!", hasher),
                    MakeUser(3, "ana@knjigoteka.local", "Ana", "Knjiga", "Ana123!", hasher)
                });
                await _db.SaveChangesAsync();
            }

            var branchCentral = await _db.Branches.FirstAsync();
            var employeeUser = await _db.Users.FirstOrDefaultAsync(u => u.Email == "radnik@knjigoteka.local");
            if (employeeUser != null && !await _db.Employees.AnyAsync(e => e.UserId == employeeUser.Id))
            {
                await _db.Employees.AddAsync(new Employee
                {
                    UserId = employeeUser.Id,
                    EmploymentDate = DateTime.UtcNow.AddYears(-1),
                    BranchId = branchCentral.Id,
                    IsActive = true
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Genres.AnyAsync())
            {
                await _db.Genres.AddRangeAsync(new[]
                {
                    new Genre { Name = "Roman" },
                    new Genre { Name = "Naučna fantastika" },
                    new Genre { Name = "Drama" },
                    new Genre { Name = "Psihologija" }
                });
                await _db.SaveChangesAsync();
            }
            if (!await _db.Languages.AnyAsync())
            {
                await _db.Languages.AddRangeAsync(new[]
                {
                    new Language { Name = "Bosanski" },
                    new Language { Name = "Engleski" },
                    new Language { Name = "Njemački" }
                });
                await _db.SaveChangesAsync();
            }

            var genreRoman = await _db.Genres.FirstAsync();
            var langBos = await _db.Languages.FirstAsync();
            if (!await _db.Books.AnyAsync())
            {
                await _db.Books.AddRangeAsync(new[]
                {
                    new Book {
                        Title = "Derviš i smrt",
                        Author = "Meša Selimović",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958002341",
                        Year = 1966,
                        Price = 21,
                        CentralStock = 14,
                        ShortDescription = "Kultni roman, filozofska drama.",
                        BookImage = LoadImageOrNull("dervis.jpg")
                    },
                    new Book {
                        Title = "Na Drini ćuprija",
                        Author = "Ivo Andrić",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958001234",
                        Year = 1945,
                        Price = 19,
                        CentralStock = 10,
                        ShortDescription = "Ep o jednom mostu i jednom gradu.",
                        BookImage = LoadImageOrNull("cuprija.jpg")
                    },
                    new Book {
                        Title = "Prokleta avlija",
                        Author = "Ivo Andrić",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958004321",
                        Year = 1954,
                        Price = 18,
                        CentralStock = 7,
                        ShortDescription = "Roman o zatvoru i krivici.",
                        BookImage = LoadImageOrNull("avlija.jpg")
                    },
                    new Book {
                        Title = "The Great Gatsby",
                        Author = "F. Scott Fitzgerald",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9780743273565",
                        Year = 1925,
                        Price = 25,
                        CentralStock = 12,
                        ShortDescription = "Kultni roman o bogatstvu i propasti u doba džez ere.",
                        BookImage = LoadImageOrNull("gatsby.jpg")
                    },
                    new Book {
                        Title = "1984",
                        Author = "George Orwell",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9780451524935",
                        Year = 1949,
                        Price = 20,
                        CentralStock = 16,
                        ShortDescription = "Distopijski roman o totalitarnoj kontroli i gubitku slobode.",
                        BookImage = LoadImageOrNull("1984.jpg")
                    }
                });
                await _db.SaveChangesAsync();
            }

            var branch1 = await _db.Branches.FirstAsync();
            var branch2 = await _db.Branches.OrderBy(x => x.Id).Skip(1).FirstAsync();
            var knjige = await _db.Books.ToListAsync();
            if (!await _db.BookBranches.AnyAsync())
            {
                await _db.BookBranches.AddRangeAsync(new[]
                {
                    new BookBranch { BranchId = branch1.Id, BookId = knjige[0].Id, QuantityForSale = 5, QuantityForBorrow = 4, SupportsBorrowing = true },
                    new BookBranch { BranchId = branch1.Id, BookId = knjige[1].Id, QuantityForSale = 2, QuantityForBorrow = 3, SupportsBorrowing = true },
                    new BookBranch { BranchId = branch2.Id, BookId = knjige[2].Id, QuantityForSale = 6, QuantityForBorrow = 1, SupportsBorrowing = true }
                });
                await _db.SaveChangesAsync();
            }

            var userPupo = await _db.Users.FirstAsync(u => u.FirstName.ToLower() == "pupo");
            var branchInv = await _db.BookBranches.FirstAsync();
            // --- SEED PAR REZERVACIJA ---
            if (!await _db.Reservations.AnyAsync())
            {
                var users = await _db.Users.OrderBy(x => x.Id).ToListAsync();
                var knjigeList = await _db.Books.ToListAsync();
                var reservations = new List<Reservation>
    {
        new Reservation
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            ReservedAt = DateTime.UtcNow.AddDays(-2),
            Status = ReservationStatus.Pending
        },
        new Reservation
        {
            UserId = users[3].Id, // Ana
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch1.Id,
            ReservedAt = DateTime.UtcNow.AddDays(-1),
            Status = ReservationStatus.Claimed,
            ClaimedAt = DateTime.UtcNow.AddHours(-22)
        },
    };
                await _db.Reservations.AddRangeAsync(reservations);
                await _db.SaveChangesAsync();
            }

            // --- SEED PAR POSUDBI ---
            if (!await _db.Borrowings.AnyAsync())
            {
                var users = await _db.Users.OrderBy(x => x.Id).ToListAsync();
                var knjigeList = await _db.Books.ToListAsync();
                var reservationAna = await _db.Reservations.FirstOrDefaultAsync(r => r.Status == ReservationStatus.Claimed);

                var borrowings = new List<Borrowing>
    {
        new Borrowing
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-5),
            DueDate = DateTime.UtcNow.AddDays(10)
        },
        new Borrowing
        {
            UserId = users[3].Id, // Ana
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch1.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-7),
            DueDate = DateTime.UtcNow.AddDays(-1),
            ReturnedAt = DateTime.UtcNow.AddDays(-2), // Vraćeno prije roka
            ReservationId = reservationAna?.Id // povezano s rezervacijom
        },
        new Borrowing
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[2].Id, // Prokleta avlija
            BranchId = branch2.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-10),
            DueDate = DateTime.UtcNow.AddDays(-2),
            ReturnedAt = null // nije vraćeno, kasni
        }
    };
                await _db.Borrowings.AddRangeAsync(borrowings);
                await _db.SaveChangesAsync();
            }


            if (!await _db.Orders.AnyAsync())
            {
                await _db.Orders.AddAsync(new Order
                {
                    UserId = userPupo.Id,
                    OrderDate = DateTime.UtcNow.AddDays(-2),
                    DeliveryAddress = "Moja adresa 123, Tuzla",
                    PaymentMethod = "gotovina",
                    TotalAmount = 41.40m
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Penalties.AnyAsync())
            {
                await _db.Penalties.AddAsync(new Penalty
                {
                    UserId = userPupo.Id,
                    Reason = "Kasni sa vraćanjem knjige",
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Reviews.AnyAsync())
            {
                await _db.Reviews.AddAsync(new Review
                {
                    UserId = userPupo.Id,
                    BookId = knjige[0].Id,
                    Rating = 5,
                    CreatedAt = DateTime.UtcNow
                });
                await _db.SaveChangesAsync();
            }
            // --- SEED PAR RESTOCK REQUESTOVA ---
            if (!await _db.RestockRequests.AnyAsync())
            {
                var knjigeList = await _db.Books.ToListAsync();
                var employee = await _db.Employees.FirstAsync();

                var restocks = new List<RestockRequest>
    {
        new RestockRequest
        {
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-8),
            QuantityRequested = 5,
            Status = RestockRequestStatus.Pending
        },
        new RestockRequest
        {
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch2.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-5),
            QuantityRequested = 3,
            Status = RestockRequestStatus.Approved
        },
        new RestockRequest
        {
            BookId = knjigeList[2].Id, // Prokleta avlija
            BranchId = branch1.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-2),
            QuantityRequested = 4,
            Status = RestockRequestStatus.Recieved
        },
        new RestockRequest
        {
            BookId = knjigeList[3].Id, // The Great Gatsby
            BranchId = branch2.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-12),
            QuantityRequested = 2,
            Status = RestockRequestStatus.Rejected
        }
    };

                await _db.RestockRequests.AddRangeAsync(restocks);
                await _db.SaveChangesAsync();
            }

            return Ok("Knjigoteka SEED complete!");
        }

        private static User MakeUser(int roleId, string email, string first, string last, string pass, PasswordHasher<User> hasher)
        {
            var u = new User
            {
                Email = email,
                FirstName = first,
                LastName = last,
                RoleId = roleId
            };
            u.PasswordHash = hasher.HashPassword(u, pass);
            return u;
        }

        private byte[]? LoadImageOrNull(string fileName)
        {
            var path = Path.Combine(_webRoot, "pics", fileName);
            if (System.IO.File.Exists(path))
                return System.IO.File.ReadAllBytes(path);
            var path2 = Path.Combine(_contentRoot, "wwwroot", "pics", fileName);
            if (System.IO.File.Exists(path2))
                return System.IO.File.ReadAllBytes(path2);
            return null;
        }
    }
}
