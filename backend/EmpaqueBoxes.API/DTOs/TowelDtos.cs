namespace EmpaqueBoxes.API.DTOs;

public record CreateTowelRequest(string ItemCode, string ProductCode);

public record TowelResponse(int TowelId, string ItemCode, string ProductCode, string Status, int? BoxId);
