namespace EmpaqueBoxes.API.Models;

public class Box
{
    public int BoxId { get; set; }
    public string BoxCode { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public string Status { get; set; } = "OPEN";   // OPEN | CLOSED
    public bool IsActive { get; set; } = true;

    public ICollection<Towel> Towels { get; set; } = new List<Towel>();
}
