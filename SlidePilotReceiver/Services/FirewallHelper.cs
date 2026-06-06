using System;
using System.Diagnostics;

namespace SlidePilotReceiver.Services;

public class FirewallHelper
{
    public void OpenFirewallSettings()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "control.exe",
                Arguments = "firewall.cpl",
                UseShellExecute = true
            });
        }
        catch (Exception)
        {
            // Fail silently or log
        }
    }
}
