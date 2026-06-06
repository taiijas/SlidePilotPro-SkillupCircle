using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace SlidePilotReceiver.Models;

public class ReceiverCommand
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty; // "keyboard", "mouse", "gesture", "system"

    [JsonPropertyName("action")]
    public string Action { get; set; } = string.Empty; // "key", "shortcut", "move", "click", "button_down", "button_up", "scroll", "ping", "pair"

    [JsonPropertyName("key")]
    public string? Key { get; set; }

    [JsonPropertyName("keys")]
    public List<string>? Keys { get; set; }

    [JsonPropertyName("dx")]
    public int? Dx { get; set; }

    [JsonPropertyName("dy")]
    public int? Dy { get; set; }

    [JsonPropertyName("button")]
    public string? Button { get; set; }

    [JsonPropertyName("delta")]
    public int? Delta { get; set; }

    [JsonPropertyName("profile")]
    public string? Profile { get; set; }

    [JsonPropertyName("pin")]
    public string? Pin { get; set; }

    [JsonPropertyName("deviceName")]
    public string? DeviceName { get; set; }
}
