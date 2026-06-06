using System.Text.Json.Serialization;

namespace SlidePilotReceiver.Models;

public class PairingPayload
{
    [JsonPropertyName("app")]
    public string App { get; set; } = "SlidePilot";

    [JsonPropertyName("mode")]
    public string Mode { get; set; } = "receiver";

    [JsonPropertyName("host")]
    public string Host { get; set; } = string.Empty;

    [JsonPropertyName("port")]
    public int Port { get; set; } = 45678;

    [JsonPropertyName("pin")]
    public string Pin { get; set; } = string.Empty;

    [JsonPropertyName("deviceName")]
    public string DeviceName { get; set; } = string.Empty;
}
