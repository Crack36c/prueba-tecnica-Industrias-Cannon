using EmpaqueBoxes.API.Data;
using EmpaqueBoxes.API.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace EmpaqueBoxes.API.Controllers;

[ApiController]
[Route("api/towels")]
public class TowelsController : ControllerBase
{
    private readonly AppDbContext _db;

    public TowelsController(AppDbContext db) => _db = db;

    // GET /api/towels
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var towels = await _db.Database
            .SqlQuery<TowelResponse>($"EXEC sp_GetActiveTowels")
            .ToListAsync();

        return Ok(towels);
    }

    // POST /api/towels
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTowelRequest req)
    {
        var pItemCode    = new SqlParameter("@ItemCode",     req.ItemCode ?? string.Empty);
        var pProductCode = new SqlParameter("@ProductCode",  req.ProductCode ?? string.Empty);
        var pNewId       = new SqlParameter("@NewTowelId",   SqlDbType.Int)   { Direction = ParameterDirection.Output };
        var pError       = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_CreateTowel @ItemCode, @ProductCode, @NewTowelId OUTPUT, @ErrorMessage OUTPUT",
            pItemCode, pProductCode, pNewId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return BadRequest(error);

        var newId = (int)pNewId.Value;
        var created = new TowelResponse(newId, req.ItemCode!, req.ProductCode!, "LOOSE", null);
        return CreatedAtAction(nameof(GetAll), created);
    }

    // PUT /api/towels/{towelId}/disable
    [HttpPut("{towelId}/disable")]
    public async Task<IActionResult> Disable(int towelId)
    {
        var pTowelId = new SqlParameter("@TowelId",      towelId);
        var pError   = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_DisableTowel @TowelId, @ErrorMessage OUTPUT",
            pTowelId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return error.Contains("no encontrada") ? NotFound(error) : BadRequest(error);

        return NoContent();
    }
}
