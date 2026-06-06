using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using SlidePilotReceiver.Models;

namespace SlidePilotReceiver.Services;

public class WebSocketReceiverService
{
    private CancellationTokenSource? _cts;
    private TcpListener? _listener;
    private WebSocket? _activeSocket;
    private TcpClient? _activeClient;
    private string _currentPin = string.Empty;
    private readonly InputInjector _inputInjector = new();

    public bool IsRunning { get; private set; }
    public string ConnectedPhoneName { get; private set; } = string.Empty;

    public event Action<string>? OnLog;
    public event Action<string>? OnPhoneConnected;
    public event Action? OnPhoneDisconnected;
    public event Action<string>? OnCommandReceived;
    public event Action? OnStatusChanged;

    public void Start(int port, string pin)
    {
        if (IsRunning) return;

        _currentPin = pin;
        _cts = new CancellationTokenSource();
        _listener = new TcpListener(IPAddress.Any, port);

        try
        {
            _listener.Start();
            IsRunning = true;
            OnStatusChanged?.Invoke();
            OnLog?.Invoke($"Receiver started on port {port}");

            _ = AcceptConnectionsAsync(_cts.Token);
        }
        catch (Exception ex)
        {
            OnLog?.Invoke($"Failed to start receiver: {ex.Message}");
            Stop();
        }
    }

    public void Stop()
    {
        if (!IsRunning) return;

        _cts?.Cancel();
        _listener?.Stop();

        DisconnectCurrentPhone();

        IsRunning = false;
        OnStatusChanged?.Invoke();
        OnLog?.Invoke("Receiver stopped");
    }

    public void DisconnectCurrentPhone()
    {
        if (_activeSocket != null && _activeSocket.State == WebSocketState.Open)
        {
            try
            {
                _ = _activeSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Disconnected by host", CancellationToken.None);
            }
            catch { }
        }
        _activeClient?.Close();
        bool wasConnected = !string.IsNullOrEmpty(ConnectedPhoneName);
        ResetActiveConnection();
        if (wasConnected)
        {
            OnLog?.Invoke("Phone disconnected by host");
            OnPhoneDisconnected?.Invoke();
        }
    }

    private void ResetActiveConnection()
    {
        _activeSocket = null;
        _activeClient = null;
        ConnectedPhoneName = string.Empty;
    }

    private async Task AcceptConnectionsAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                TcpClient client = await _listener!.AcceptTcpClientAsync(ct);
                _ = HandleClientConnectionAsync(client, ct);
            }
            catch (ObjectDisposedException)
            {
                break; // Listener was stopped
            }
            catch (Exception ex)
            {
                if (!ct.IsCancellationRequested)
                {
                    OnLog?.Invoke($"Error accepting connection: {ex.Message}");
                }
            }
        }
    }

    private async Task HandleClientConnectionAsync(TcpClient client, CancellationToken ct)
    {
        IPEndPoint? remoteEp = client.Client.RemoteEndPoint as IPEndPoint;
        if (remoteEp == null)
        {
            client.Close();
            return;
        }

        if (!IsLocalAddress(remoteEp.Address))
        {
            OnLog?.Invoke($"Rejected connection from non-local IP: {remoteEp.Address}");
            client.Close();
            return;
        }

        if (_activeClient != null)
        {
            OnLog?.Invoke($"Connection from {remoteEp.Address} rejected: another device is already connected");
            client.Close();
            return;
        }

        _activeClient = client;
        NetworkStream stream = client.GetStream();

        try
        {
            // 1. Perform WebSocket handshake
            string? acceptKey = await HandleHandshakeAsync(stream);
            if (acceptKey == null)
            {
                OnLog?.Invoke($"Handshake failed with client {remoteEp.Address}");
                client.Close();
                if (_activeClient == client) _activeClient = null;
                return;
            }

            // 2. Upgrade stream to WebSocket
            WebSocket webSocket = WebSocket.CreateFromStream(stream, isServer: true, subProtocol: null, keepAliveInterval: TimeSpan.FromSeconds(30));
            _activeSocket = webSocket;

            // 3. Perform Pairing verification with a 10s timeout
            using (var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(10)))
            using (var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(ct, timeoutCts.Token))
            {
                bool authenticated = await AuthenticateClientAsync(webSocket, linkedCts.Token);
                if (!authenticated)
                {
                    OnLog?.Invoke($"Pairing failed for client {remoteEp.Address}");
                    await SendResponseAsync(webSocket, new { ok = false, error = "invalid pin" }, ct);
                    try
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Authentication Failed", ct);
                    }
                    catch { }
                    client.Close();
                    ResetActiveConnection();
                    return;
                }
            }

            // 4. Client paired successfully
            await SendResponseAsync(webSocket, new { ok = true, message = "paired successfully" }, ct);
            OnLog?.Invoke($"Phone paired: {ConnectedPhoneName} ({remoteEp.Address})");
            OnPhoneConnected?.Invoke(ConnectedPhoneName);

            // 5. Command loop
            byte[] receiveBuffer = new byte[4096];
            while (webSocket.State == WebSocketState.Open && !ct.IsCancellationRequested)
            {
                string? messageJson = await ReceiveTextMessageAsync(webSocket, receiveBuffer, ct);
                if (messageJson == null)
                {
                    break; // Socket closed or error
                }

                try
                {
                    var command = JsonSerializer.Deserialize<ReceiverCommand>(messageJson);
                    if (command != null)
                    {
                        bool ok = ProcessCommand(command, out string cmdDesc, out string errorMsg);
                        if (ok)
                        {
                            await SendResponseAsync(webSocket, new { ok = true, message = "command executed" }, ct);
                            OnCommandReceived?.Invoke(cmdDesc);
                        }
                        else
                        {
                            await SendResponseAsync(webSocket, new { ok = false, error = errorMsg }, ct);
                            OnLog?.Invoke($"Command execution error: {errorMsg}");
                        }
                    }
                    else
                    {
                        await SendResponseAsync(webSocket, new { ok = false, error = "invalid command format" }, ct);
                    }
                }
                catch (Exception ex)
                {
                    await SendResponseAsync(webSocket, new { ok = false, error = ex.Message }, ct);
                    OnLog?.Invoke($"Error parsing command: {ex.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            if (!ct.IsCancellationRequested)
            {
                OnLog?.Invoke($"Connection error with {remoteEp.Address}: {ex.Message}");
            }
        }
        finally
        {
            client.Close();
            bool wasConnected = !string.IsNullOrEmpty(ConnectedPhoneName);
            ResetActiveConnection();
            if (wasConnected)
            {
                OnLog?.Invoke("Phone disconnected");
                OnPhoneDisconnected?.Invoke();
            }
        }
    }

    private async Task<bool> AuthenticateClientAsync(WebSocket webSocket, CancellationToken ct)
    {
        byte[] receiveBuffer = new byte[4096];
        string? messageJson = await ReceiveTextMessageAsync(webSocket, receiveBuffer, ct);
        if (messageJson == null) return false;

        try
        {
            var command = JsonSerializer.Deserialize<ReceiverCommand>(messageJson);
            if (command != null && command.Type == "system" && command.Action == "pair")
            {
                if (command.Pin == _currentPin)
                {
                    ConnectedPhoneName = string.IsNullOrEmpty(command.DeviceName) ? "Unknown Phone" : command.DeviceName;
                    return true;
                }
            }
        }
        catch (Exception)
        {
            // Ignore parsing errors
        }

        return false;
    }

    private async Task<string?> ReceiveTextMessageAsync(WebSocket webSocket, byte[] buffer, CancellationToken ct)
    {
        using (var ms = new MemoryStream())
        {
            WebSocketReceiveResult result;
            do
            {
                result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), ct);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    try
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by client", ct);
                    }
                    catch { }
                    return null;
                }
                ms.Write(buffer, 0, result.Count);
            } while (!result.EndOfMessage);

            return Encoding.UTF8.GetString(ms.ToArray());
        }
    }

    private async Task SendResponseAsync(WebSocket webSocket, object response, CancellationToken ct)
    {
        try
        {
            string json = JsonSerializer.Serialize(response);
            byte[] bytes = Encoding.UTF8.GetBytes(json);
            if (webSocket.State == WebSocketState.Open)
            {
                await webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, ct);
            }
        }
        catch { }
    }

    private async Task<string?> HandleHandshakeAsync(NetworkStream stream)
    {
        StringBuilder requestBuilder = new StringBuilder();
        byte[] buffer = new byte[1024];
        
        // Read headers until \r\n\r\n
        while (!requestBuilder.ToString().Contains("\r\n\r\n"))
        {
            int bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length);
            if (bytesRead == 0) break;
            requestBuilder.Append(Encoding.UTF8.GetString(buffer, 0, bytesRead));
        }
        
        string request = requestBuilder.ToString();

        if (!request.Contains("Upgrade: websocket", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        string keyHeader = "Sec-WebSocket-Key: ";
        int keyStart = request.IndexOf(keyHeader, StringComparison.OrdinalIgnoreCase);
        if (keyStart == -1) return null;

        int keyEnd = request.IndexOf("\r\n", keyStart);
        if (keyEnd == -1) return null;

        string key = request.Substring(keyStart + keyHeader.Length, keyEnd - (keyStart + keyHeader.Length)).Trim();

        string concat = key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
        byte[] concatBytes = Encoding.UTF8.GetBytes(concat);
        byte[] sha1Bytes = System.Security.Cryptography.SHA1.HashData(concatBytes);
        string acceptKey = Convert.ToBase64String(sha1Bytes);

        string response = "HTTP/1.1 101 Switching Protocols\r\n" +
                          "Upgrade: websocket\r\n" +
                          "Connection: Upgrade\r\n" +
                          "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n";

        byte[] responseBytes = Encoding.UTF8.GetBytes(response);
        await stream.WriteAsync(responseBytes, 0, responseBytes.Length);
        await stream.FlushAsync();

        return acceptKey;
    }

    private bool IsLocalAddress(IPAddress address)
    {
        if (IPAddress.IsLoopback(address)) return true;

        if (address.IsIPv4MappedToIPv6)
        {
            address = address.MapToIPv4();
        }

        byte[] bytes = address.GetAddressBytes();
        if (bytes.Length == 4)
        {
            // 10.0.0.0 - 10.255.255.255
            if (bytes[0] == 10) return true;
            // 172.16.0.0 - 172.31.255.255
            if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) return true;
            // 192.168.0.0 - 192.168.255.255
            if (bytes[0] == 192 && bytes[1] == 168) return true;
            // Link-local: 169.254.0.0 - 169.254.255.255
            if (bytes[0] == 169 && bytes[1] == 254) return true;
        }
        else if (bytes.Length == 16)
        {
            // IPv6 link local (fe80::/10)
            if (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80) return true;
            // IPv6 unique local (fc00::/7)
            if ((bytes[0] & 0xfe) == 0xfc) return true;
        }

        return false;
    }

    private bool ProcessCommand(ReceiverCommand command, out string cmdDesc, out string errorMsg)
    {
        cmdDesc = string.Empty;
        errorMsg = string.Empty;

        try
        {
            switch (command.Type.ToLowerInvariant())
            {
                case "keyboard":
                    if (command.Action.Equals("key", StringComparison.OrdinalIgnoreCase))
                    {
                        if (string.IsNullOrEmpty(command.Key))
                        {
                            errorMsg = "Key parameter is missing";
                            return false;
                        }
                        _inputInjector.SendKey(command.Key);
                        cmdDesc = $"Key: {command.Key}";
                        return true;
                    }
                    else if (command.Action.Equals("shortcut", StringComparison.OrdinalIgnoreCase))
                    {
                        if (command.Keys == null || command.Keys.Count == 0)
                        {
                            errorMsg = "Shortcut keys parameter is missing";
                            return false;
                        }
                        _inputInjector.SendShortcut(command.Keys);
                        cmdDesc = $"Shortcut: {string.Join(" + ", command.Keys)}";
                        return true;
                    }
                    errorMsg = $"Unknown keyboard action: {command.Action}";
                    return false;

                case "mouse":
                    if (command.Action.Equals("move", StringComparison.OrdinalIgnoreCase))
                    {
                        if (command.Dx == null || command.Dy == null)
                        {
                            errorMsg = "dx or dy missing";
                            return false;
                        }
                        _inputInjector.MouseMove(command.Dx.Value, command.Dy.Value);
                        cmdDesc = $"Mouse Move: dx={command.Dx}, dy={command.Dy}";
                        return true;
                    }
                    else if (command.Action.Equals("click", StringComparison.OrdinalIgnoreCase))
                    {
                        if (string.IsNullOrEmpty(command.Button))
                        {
                            errorMsg = "Mouse button missing";
                            return false;
                        }
                        _inputInjector.MouseClick(command.Button);
                        cmdDesc = $"Mouse Click: {command.Button}";
                        return true;
                    }
                    else if (command.Action.Equals("button_down", StringComparison.OrdinalIgnoreCase))
                    {
                        if (string.IsNullOrEmpty(command.Button))
                        {
                            errorMsg = "Mouse button missing";
                            return false;
                        }
                        _inputInjector.MouseButtonDown(command.Button);
                        cmdDesc = $"Mouse Down: {command.Button}";
                        return true;
                    }
                    else if (command.Action.Equals("button_up", StringComparison.OrdinalIgnoreCase))
                    {
                        if (string.IsNullOrEmpty(command.Button))
                        {
                            errorMsg = "Mouse button missing";
                            return false;
                        }
                        _inputInjector.MouseButtonUp(command.Button);
                        cmdDesc = $"Mouse Up: {command.Button}";
                        return true;
                    }
                    else if (command.Action.Equals("scroll", StringComparison.OrdinalIgnoreCase))
                    {
                        if (command.Delta == null)
                        {
                            errorMsg = "Scroll delta missing";
                            return false;
                        }
                        _inputInjector.MouseScroll(command.Delta.Value);
                        cmdDesc = $"Mouse Scroll: delta={command.Delta}";
                        return true;
                    }
                    errorMsg = $"Unknown mouse action: {command.Action}";
                    return false;

                case "gesture":
                    return ProcessGesture(command, out cmdDesc, out errorMsg);

                case "system":
                    if (command.Action.Equals("ping", StringComparison.OrdinalIgnoreCase))
                    {
                        cmdDesc = "System: Ping";
                        return true;
                    }
                    errorMsg = $"Unknown system action: {command.Action}";
                    return false;

                default:
                    errorMsg = $"Unknown command type: {command.Type}";
                    return false;
            }
        }
        catch (Exception ex)
        {
            errorMsg = ex.Message;
            return false;
        }
    }

    private bool ProcessGesture(ReceiverCommand command, out string cmdDesc, out string errorMsg)
    {
        cmdDesc = string.Empty;
        errorMsg = string.Empty;

        switch (command.Action.ToLowerInvariant())
        {
            case "three_finger_swipe_up":
                _inputInjector.SendShortcut(new List<string> { "win", "tab" });
                cmdDesc = "Gesture: 3-finger swipe up -> Win + Tab";
                return true;

            case "three_finger_swipe_down":
                _inputInjector.SendShortcut(new List<string> { "win", "d" });
                cmdDesc = "Gesture: 3-finger swipe down -> Win + D";
                return true;

            case "three_finger_swipe_left":
                _inputInjector.SendShortcut(new List<string> { "alt", "tab" });
                cmdDesc = "Gesture: 3-finger swipe left -> Alt + Tab";
                return true;

            case "three_finger_swipe_right":
                _inputInjector.SendShortcut(new List<string> { "alt", "shift", "tab" });
                cmdDesc = "Gesture: 3-finger swipe right -> Alt + Shift + Tab";
                return true;

            case "four_finger_swipe_left":
                _inputInjector.SendShortcut(new List<string> { "ctrl", "win", "left" });
                cmdDesc = "Gesture: 4-finger swipe left -> Ctrl + Win + Left";
                return true;

            case "four_finger_swipe_right":
                _inputInjector.SendShortcut(new List<string> { "ctrl", "win", "right" });
                cmdDesc = "Gesture: 4-finger swipe right -> Ctrl + Win + Right";
                return true;

            case "pinch_out":
                _inputInjector.SendShortcut(new List<string> { "ctrl", "plus" });
                cmdDesc = "Gesture: Pinch out -> Ctrl + Plus";
                return true;

            case "pinch_in":
                _inputInjector.SendShortcut(new List<string> { "ctrl", "minus" });
                cmdDesc = "Gesture: Pinch in -> Ctrl + Minus";
                return true;

            case "two_finger_scroll":
                int delta = command.Delta ?? 120;
                _inputInjector.MouseScroll(delta);
                cmdDesc = $"Gesture: 2-finger scroll -> scroll {delta}";
                return true;

            case "two_finger_tap":
                _inputInjector.MouseClick("right");
                cmdDesc = "Gesture: 2-finger tap -> Right Click";
                return true;

            default:
                errorMsg = $"Unknown gesture action: {command.Action}";
                return false;
        }
    }
}
