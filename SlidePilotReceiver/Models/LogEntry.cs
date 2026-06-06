using System;

namespace SlidePilotReceiver.Models;

public class LogEntry
{
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public string Message { get; set; } = string.Empty;

    public string FormattedText => $"[{Timestamp:HH:mm:ss}] {Message}";
}
