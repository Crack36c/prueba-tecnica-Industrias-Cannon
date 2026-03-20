using Microsoft.EntityFrameworkCore.Diagnostics;
using System.Data.Common;

namespace EmpaqueBoxes.API.Infrastructure;

/// <summary>
/// Fuerza SET QUOTED_IDENTIFIER ON en cada conexión abierta por EF Core.
/// Requerido para operar sobre tablas con índices filtrados (WHERE IsActive = 1).
/// </summary>
public class QuotedIdentifierInterceptor : DbConnectionInterceptor
{
    public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = "SET QUOTED_IDENTIFIER ON";
        cmd.ExecuteNonQuery();
    }

    public override async Task ConnectionOpenedAsync(DbConnection connection, ConnectionEndEventData eventData, CancellationToken cancellationToken = default)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "SET QUOTED_IDENTIFIER ON";
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
