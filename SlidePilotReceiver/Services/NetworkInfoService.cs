using System;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;

namespace SlidePilotReceiver.Services;

public class NetworkInfoService
{
    public string GetLocalIPAddress()
    {
        try
        {
            // Traverse network interfaces to find active non-loopback IPv4 addresses
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus == OperationalStatus.Up && 
                    ni.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                {
                    var ipProps = ni.GetIPProperties();
                    foreach (var addr in ipProps.UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily == AddressFamily.InterNetwork)
                        {
                            string ip = addr.Address.ToString();
                            // Check typical local address ranges
                            if (ip.StartsWith("192.168.") || ip.StartsWith("10.") || ip.StartsWith("172."))
                            {
                                return ip;
                            }
                        }
                    }
                }
            }

            // Fallback: first active interface IPv4 address
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus == OperationalStatus.Up)
                {
                    var ipProps = ni.GetIPProperties();
                    foreach (var addr in ipProps.UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily == AddressFamily.InterNetwork)
                        {
                            return addr.Address.ToString();
                        }
                    }
                }
            }
        }
        catch (Exception)
        {
            // Ignore and fall through to localhost
        }

        return "127.0.0.1";
    }
}
