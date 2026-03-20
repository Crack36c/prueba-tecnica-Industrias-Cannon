using EmpaqueBoxes.API.Data;
using EmpaqueBoxes.API.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace EmpaqueBoxes.API.Controllers;

[ApiController]
[Route("api/boxes")]
public class BoxesController : ControllerBase
{
    private readonly AppDbContext _db;

    public BoxesController(AppDbContext db) => _db = db;

    // GET /api/boxes
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var boxes = await _db.Database
            .SqlQuery<BoxResponse>($"EXEC sp_GetActiveBoxes")
            .ToListAsync();

        return Ok(boxes);
    }

    // POST /api/boxes
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBoxRequest req)
    {
        var pBoxCode     = new SqlParameter("@BoxCode",      req.BoxCode ?? string.Empty);
        var pProductCode = new SqlParameter("@ProductCode",  req.ProductCode ?? string.Empty);
        var pCapacity    = new SqlParameter("@Capacity",     req.Capacity);
        var pNewId       = new SqlParameter("@NewBoxId",     SqlDbType.Int)   { Direction = ParameterDirection.Output };
        var pError       = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_CreateBox @BoxCode, @ProductCode, @Capacity, @NewBoxId OUTPUT, @ErrorMessage OUTPUT",
            pBoxCode, pProductCode, pCapacity, pNewId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return BadRequest(error);

        var newId   = (int)pNewId.Value;
        var created = new BoxResponse(newId, req.BoxCode!, req.ProductCode!, req.Capacity, 0, "OPEN");
        return CreatedAtAction(nameof(GetAll), created);
    }

    // PUT /api/boxes/{boxId}/disable
    [HttpPut("{boxId}/disable")]
    public async Task<IActionResult> Disable(int boxId)
    {
        var pBoxId = new SqlParameter("@BoxId",        boxId);
        var pError = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_DisableBox @BoxId, @ErrorMessage OUTPUT",
            pBoxId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return error.Contains("no encontrada") ? NotFound(error) : BadRequest(error);

        return NoContent();
    }

    // POST /api/boxes/{boxId}/pack
    [HttpPost("{boxId}/pack")]
    public async Task<IActionResult> Pack(int boxId, [FromBody] PackUnpackRequest req)
    {
        var pBoxId   = new SqlParameter("@BoxId",        boxId);
        var pTowelId = new SqlParameter("@TowelId",      req.TowelId);
        var pError   = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_PackTowel @BoxId, @TowelId, @ErrorMessage OUTPUT",
            pBoxId, pTowelId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return error.Contains("no encontrada") ? NotFound(error) : BadRequest(error);

        return Ok(new { message = "Unidad empacada correctamente." });
    }

    // POST /api/boxes/{boxId}/unpack
    [HttpPost("{boxId}/unpack")]
    public async Task<IActionResult> Unpack(int boxId, [FromBody] PackUnpackRequest req)
    {
        var pBoxId   = new SqlParameter("@BoxId",        boxId);
        var pTowelId = new SqlParameter("@TowelId",      req.TowelId);
        var pError   = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_UnpackTowel @BoxId, @TowelId, @ErrorMessage OUTPUT",
            pBoxId, pTowelId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return error.Contains("no encontrada") ? NotFound(error) : BadRequest(error);

        return Ok(new { message = "Unidad sacada correctamente." });
    }

    // POST /api/boxes/{boxId}/close
    [HttpPost("{boxId}/close")]
    public async Task<IActionResult> Close(int boxId)
    {
        var pBoxId = new SqlParameter("@BoxId",        boxId);
        var pError = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };

        await _db.Database.ExecuteSqlRawAsync(
            "EXEC sp_CloseBox @BoxId, @ErrorMessage OUTPUT",
            pBoxId, pError);

        var error = pError.Value as string;
        if (!string.IsNullOrEmpty(error))
            return error.Contains("no encontrada") ? NotFound(error) : BadRequest(error);

        return Ok(new { message = "Caja cerrada correctamente." });
    }
}
