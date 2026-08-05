namespace Smart_Queue.DTOs;

public class TimeSlotResponseDto
{
    public string Time { get; set; } = string.Empty;
    public bool Available { get; set; }
    public double CrowdLevel { get; set; }
    public int WaitTime { get; set; }
}
