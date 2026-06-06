using System;
using System.Text.Json;
using QRCoder;
using SlidePilotReceiver.Models;

namespace SlidePilotReceiver.Services;

public class PairingService
{
    public string GeneratePin()
    {
        Random random = new Random();
        return random.Next(100000, 999999).ToString();
    }

    public byte[] GenerateQrCodePng(string host, int port, string pin)
    {
        var payload = new PairingPayload
        {
            App = "SlidePilot",
            Mode = "receiver",
            Host = host,
            Port = port,
            Pin = pin,
            DeviceName = Environment.MachineName
        };

        string json = JsonSerializer.Serialize(payload);

        using (QRCodeGenerator qrGenerator = new QRCodeGenerator())
        {
            using (QRCodeData qrCodeData = qrGenerator.CreateQrCode(json, QRCodeGenerator.ECCLevel.Q))
            {
                using (PngByteQRCode qrCode = new PngByteQRCode(qrCodeData))
                {
                    return qrCode.GetGraphic(20);
                }
            }
        }
    }
}
