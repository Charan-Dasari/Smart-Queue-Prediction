using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Smart_Queue.Data;
using Smart_Queue.Models;
using System.Security.Claims;

namespace Smart_Queue.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClaimController : ControllerBase
    {
        private readonly SmartQueueDbContext _context;

        public ClaimController(SmartQueueDbContext context)
        {
            _context = context;
        }

        // POST: api/claim/{providerId}
        // Allows a normal user to submit a claim for a business
        [HttpPost("{providerId}")]
        [Authorize(Roles = "User, Admin, Staff")]
        public async Task<IActionResult> SubmitClaim(Guid providerId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized("Invalid user token.");
            }

            // Check if place exists
            var placeExists = await _context.Places.AnyAsync(p => p.Id == providerId);
            if (!placeExists)
            {
                return NotFound("Place not found.");
            }

            // Check if user already submitted a pending claim for this provider
            var existingClaim = await _context.ClaimRequests
                .FirstOrDefaultAsync(c => c.UserId == userId && c.ProviderId == providerId && c.Status == "Pending");

            if (existingClaim != null)
            {
                return BadRequest("You already have a pending claim for this business.");
            }

            var claim = new ClaimRequest
            {
                UserId = userId,
                ProviderId = providerId,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            _context.ClaimRequests.Add(claim);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Claim request submitted successfully and is pending approval." });
        }

        // GET: api/claim/pending
        // Allows Super Admin to fetch all pending claims
        [HttpGet("pending")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> GetPendingClaims()
        {
            var claims = await _context.ClaimRequests
                .Include(c => c.User)
                .Where(c => c.Status == "Pending")
                .Select(c => new
                {
                    c.Id,
                    c.UserId,
                    UserName = c.User.Name,
                    UserEmail = c.User.Email,
                    c.ProviderId,
                    c.CreatedAt,
                    c.Status
                })
                .ToListAsync();

            // We can also try to fetch the place name for these claims
            var providerIds = claims.Select(c => c.ProviderId).Distinct().ToList();
            var places = await _context.Places
                .Where(p => providerIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, p => p.Name);

            var result = claims.Select(c => new
            {
                c.Id,
                c.UserId,
                c.UserName,
                c.UserEmail,
                c.ProviderId,
                ProviderName = places.ContainsKey(c.ProviderId) ? places[c.ProviderId] : "Unknown",
                c.CreatedAt,
                c.Status
            });

            return Ok(result);
        }

        // POST: api/claim/{id}/approve
        // Super Admin approves a claim
        [HttpPost("{id}/approve")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> ApproveClaim(int id)
        {
            var claim = await _context.ClaimRequests.FindAsync(id);
            if (claim == null) return NotFound("Claim request not found.");
            
            if (claim.Status != "Pending") return BadRequest("Claim is not pending.");

            var user = await _context.Users.FindAsync(claim.UserId);
            if (user == null) return NotFound("User not found.");

            // Update Claim
            claim.Status = "Approved";

            // Update User to Admin for this provider
            user.Role = UserRole.Admin;
            user.ProviderId = claim.ProviderId;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Claim approved successfully. User is now an Admin for this provider." });
        }

        // POST: api/claim/{id}/reject
        // Super Admin rejects a claim
        [HttpPost("{id}/reject")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> RejectClaim(int id)
        {
            var claim = await _context.ClaimRequests.FindAsync(id);
            if (claim == null) return NotFound("Claim request not found.");
            
            if (claim.Status != "Pending") return BadRequest("Claim is not pending.");

            claim.Status = "Rejected";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Claim rejected successfully." });
        }
    }
}
