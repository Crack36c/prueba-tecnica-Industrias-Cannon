namespace EmpaqueBoxes.API.DTOs;

public record CreateBoxRequest(string BoxCode, string ProductCode, int Capacity);

public record BoxResponse(int BoxId, string BoxCode, string ProductCode, int Capacity, int CurrentCount, string Status);

public record PackUnpackRequest(int TowelId);
