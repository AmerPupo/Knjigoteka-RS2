﻿using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

public class BorrowingService : IBorrowingService
{
    private readonly DatabaseContext _context;
    private readonly IUserContext _user;
    private readonly IPenaltyService _penalty;

    public BorrowingService(DatabaseContext context, IUserContext user, IPenaltyService penalty)
    {
        _context = context;
        _user = user;
        _penalty = penalty;
    }
    public async Task<BorrowingResponse> CreateAsync(BorrowingCreate req)
    {
        var branchId = _user.BranchId ?? throw new UnauthorizedAccessException();
        var bookBranch = await _context.BookBranches
            .FirstOrDefaultAsync(bb => bb.BranchId == branchId && bb.BookId == req.BookId);
        if (bookBranch == null || !bookBranch.SupportsBorrowing)
            throw new InvalidOperationException("Book is not borrowable at this branch.");

        if (bookBranch.QuantityForBorrow <= 0)
            throw new InvalidOperationException("No available copies for borrowing at this branch.");

        if (req.ReservationId.HasValue)
        {
            var reservation = await _context.Reservations.FindAsync(req.ReservationId.Value);
            if (reservation == null || reservation.UserId != req.UserId
                || reservation.BookId != req.BookId || reservation.BranchId != branchId
                || reservation.Status != ReservationStatus.Pending)
            {
                throw new InvalidOperationException("Invalid reservation for this borrowing.");
            }
            reservation.Status = ReservationStatus.Claimed;
            reservation.ClaimedAt = DateTime.Now;
        }

        var borrowing = new Borrowing
        {
            BookId = req.BookId,
            UserId = req.UserId,
            BranchId = branchId,
            ReservationId = req.ReservationId,
            BorrowedAt = DateTime.Now,
            DueDate = DateTime.Now.AddDays(30)
        };
        bookBranch.QuantityForBorrow -= 1;

        _context.Borrowings.Add(borrowing);
        await _context.SaveChangesAsync();

        var full = await _context.Borrowings
            .Include(b => b.Book)
            .Include(b => b.User)
            .Include(b => b.Branch)
            .FirstAsync(b => b.Id == borrowing.Id);

        return MapToDto(full);
    }

    public async Task<bool> ReturnAsync(int borrowingId)
    {
        var branchId = _user.BranchId ?? throw new UnauthorizedAccessException();

        var borrowing = await _context.Borrowings
            .Include(b => b.Book)
            .Include(b => b.User)
            .Include(b => b.Branch)
            .FirstOrDefaultAsync(b => b.Id == borrowingId);

        if (borrowing == null) return false;
        if(borrowing.BranchId != branchId) throw new UnauthorizedAccessException("You are not employed at this branch.");
        if (borrowing.ReturnedAt != null) throw new InvalidOperationException("Book already returned.");

        borrowing.ReturnedAt = DateTime.Now;

        var bookBranch = await _context.BookBranches
            .FirstOrDefaultAsync(bb => bb.BranchId == borrowing.BranchId && bb.BookId == borrowing.BookId);
        if (bookBranch != null)
            bookBranch.QuantityForBorrow += 1;

        if (borrowing.ReturnedAt > borrowing.DueDate)
            await _penalty.AddAsync(borrowing.UserId, "Late return");

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<BorrowingResponse>> GetMineAsync()
    {
        var userId = _user.UserId;
        var items = await _context.Borrowings
            .Include(b => b.Book).Include(b => b.Branch).Include(b => b.User)
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.BorrowedAt)
            .ToListAsync();
        return items.Select(MapToDto).ToList();
    }

    public async Task<List<BorrowingResponse>> GetByUserAsync(int userId)
    {
        var branchId = _user.BranchId ?? throw new UnauthorizedAccessException();
        var items = await _context.Borrowings
            .Include(b => b.Book).Include(b => b.Branch).Include(b => b.User)
            .Where(b => b.UserId == userId && b.BranchId == branchId)
            .OrderByDescending(b => b.BorrowedAt)
            .ToListAsync();
        return items.Select(MapToDto).ToList();
    }

    public async Task<List<BorrowingResponse>> GetByBranchAsync(int? branchId)
    {
        if(_user.Role == "Employee")
             branchId = _user.BranchId ?? throw new UnauthorizedAccessException();
        else if (branchId == null)
            throw new ArgumentException("BranchId is required for admins.");
        var items = await _context.Borrowings
            .Include(b => b.Book).Include(b => b.Branch).Include(b => b.User)
            .Where(b => b.BranchId == branchId)
            .OrderByDescending(b => b.BorrowedAt)
            .ToListAsync();
        return items.Select(MapToDto).ToList();
    }

    public async Task<List<BorrowingResponse>> GetAllAsync()
    {
        var items = await _context.Borrowings
            .Include(b => b.Book).Include(b => b.Branch).Include(b => b.User)
            .OrderByDescending(b => b.BorrowedAt)
            .ToListAsync();
        return items.Select(MapToDto).ToList();
    }
    public async Task<bool> DeleteAsync(int id)
    {
        var branchId = _user.BranchId ?? throw new UnauthorizedAccessException();
        var borrowing = await _context.Borrowings.FirstOrDefaultAsync(b => b.Id == id && b.BranchId == branchId);
        if (borrowing == null) return false;
        if (borrowing.ReturnedAt == null)
        {
            var bookBranch = await _context.BookBranches.FirstOrDefaultAsync(bb => bb.BranchId == borrowing.BranchId && bb.BookId == borrowing.BookId);
            if (bookBranch != null)
                bookBranch.QuantityForBorrow += 1;
        }
        _context.Borrowings.Remove(borrowing);
        await _context.SaveChangesAsync();
        return true;
    }

    private static BorrowingResponse MapToDto(Borrowing b) => new()
    {
        Id = b.Id,
        BookId = b.BookId,
        BookTitle = b.Book?.Title ?? "",
        UserId = b.UserId,
        UserFullName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}" : "",
        BranchId = b.BranchId,
        BranchName = b.Branch?.Name ?? "",
        ReservationId = b.ReservationId,
        BorrowedAt = b.BorrowedAt,
        DueDate = b.DueDate,
        ReturnedAt = b.ReturnedAt,
        IsLate = b.ReturnedAt.HasValue && b.ReturnedAt > b.DueDate
    };
}
