using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using SlidePilotReceiver.Services;

namespace SlidePilotReceiver.ViewModels;

public class MainViewModel : INotifyPropertyChanged
{
    private readonly WebSocketReceiverService _webSocketService;
    private readonly PairingService _pairingService;
    private readonly NetworkInfoService _networkInfoService;
    private readonly FirewallHelper _firewallHelper;

    private string _receiverStatus = "Stopped";
    private string _connectionStatus = "Waiting";
    private string _connectedPhoneName = "None";
    private string _localIpAddress = "127.0.0.1";
    private int _port = 45678;
    private string _pairingPin = string.Empty;
    private BitmapImage? _qrCodeImage;
    private string _lastCommand = "None";
    private int _commandCount = 0;
    private string _appVersion = "1.0.0";

    public ObservableCollection<string> Logs { get; } = new();
    private readonly Dispatcher _dispatcher;

    public event PropertyChangedEventHandler? PropertyChanged;

    public MainViewModel(
        WebSocketReceiverService webSocketService,
        PairingService pairingService,
        NetworkInfoService networkInfoService,
        FirewallHelper firewallHelper)
    {
        _webSocketService = webSocketService;
        _pairingService = pairingService;
        _networkInfoService = networkInfoService;
        _firewallHelper = firewallHelper;
        _dispatcher = Dispatcher.CurrentDispatcher;

        // Initialize commands
        StartCommand = new RelayCommand(StartReceiver, () => !IsReceiverRunning);
        StopCommand = new RelayCommand(StopReceiver, () => IsReceiverRunning);
        RegeneratePinCommand = new RelayCommand(RegeneratePin, () => IsReceiverRunning);
        CopyIPCommand = new RelayCommand(CopyIPAddress);
        DisconnectPhoneCommand = new RelayCommand(DisconnectPhone, () => IsPhoneConnected);
        OpenFirewallHelpCommand = new RelayCommand(OpenFirewallHelp);
        ExitCommand = new RelayCommand(ExitApp);

        // Bind events from service
        _webSocketService.OnLog += Log;
        _webSocketService.OnStatusChanged += UpdateReceiverState;
        _webSocketService.OnPhoneConnected += PhoneConnected;
        _webSocketService.OnPhoneDisconnected += PhoneDisconnected;
        _webSocketService.OnCommandReceived += CommandReceived;

        // Initial IP load
        LocalIPAddress = _networkInfoService.GetLocalIPAddress();

        Log("SlidePilot Receiver Initialized.");
    }

    public string ReceiverStatus
    {
        get => _receiverStatus;
        set => SetField(ref _receiverStatus, value);
    }

    public string ConnectionStatus
    {
        get => _connectionStatus;
        set => SetField(ref _connectionStatus, value);
    }

    public string ConnectedPhoneName
    {
        get => _connectedPhoneName;
        set => SetField(ref _connectedPhoneName, value);
    }

    public string LocalIPAddress
    {
        get => _localIpAddress;
        set => SetField(ref _localIpAddress, value);
    }

    public int Port
    {
        get => _port;
        set => SetField(ref _port, value);
    }

    public string PairingPIN
    {
        get => _pairingPin;
        set => SetField(ref _pairingPin, value);
    }

    public BitmapImage? QrCodeImage
    {
        get => _qrCodeImage;
        set => SetField(ref _qrCodeImage, value);
    }

    public string LastCommand
    {
        get => _lastCommand;
        set => SetField(ref _lastCommand, value);
    }

    public int CommandCount
    {
        get => _commandCount;
        set => SetField(ref _commandCount, value);
    }

    public string AppVersion
    {
        get => _appVersion;
        set => SetField(ref _appVersion, value);
    }

    public bool IsReceiverRunning => _webSocketService.IsRunning;
    public bool IsPhoneConnected => !string.IsNullOrEmpty(_webSocketService.ConnectedPhoneName);

    public ICommand StartCommand { get; }
    public ICommand StopCommand { get; }
    public ICommand RegeneratePinCommand { get; }
    public ICommand CopyIPCommand { get; }
    public ICommand DisconnectPhoneCommand { get; }
    public ICommand OpenFirewallHelpCommand { get; }
    public ICommand ExitCommand { get; }

    public void StartReceiver()
    {
        LocalIPAddress = _networkInfoService.GetLocalIPAddress();
        PairingPIN = _pairingService.GeneratePin();
        GenerateQrCode();

        _webSocketService.Start(Port, PairingPIN);
        CommandManager.InvalidateRequerySuggested();
    }

    public void StopReceiver()
    {
        _webSocketService.Stop();
        PairingPIN = string.Empty;
        QrCodeImage = null;
        CommandManager.InvalidateRequerySuggested();
    }

    public void RegeneratePin()
    {
        if (!IsReceiverRunning) return;

        if (IsPhoneConnected)
        {
            _webSocketService.DisconnectCurrentPhone();
        }

        PairingPIN = _pairingService.GeneratePin();
        GenerateQrCode();

        // Restart with new PIN
        _webSocketService.Stop();
        _webSocketService.Start(Port, PairingPIN);
        Log("Pairing PIN regenerated and receiver restarted.");
        CommandManager.InvalidateRequerySuggested();
    }

    public void CopyIPAddress()
    {
        try
        {
            System.Windows.Clipboard.SetText(LocalIPAddress);
            Log("IP Address copied to clipboard.");
        }
        catch (Exception ex)
        {
            Log($"Failed to copy IP: {ex.Message}");
        }
    }

    public void DisconnectPhone()
    {
        _webSocketService.DisconnectCurrentPhone();
    }

    public void ExitApp()
    {
        (System.Windows.Application.Current as App)?.ShutdownApp();
    }

    public void OpenFirewallHelp()
    {
        _firewallHelper.OpenFirewallSettings();

        string helpMsg = "Firewall Help:\n\n" +
                         "1. Keep phone and laptop on the SAME Wi-Fi network.\n" +
                         "2. Allow this application through Windows Defender Firewall.\n" +
                         "3. Set your Wi-Fi network profile to 'Private' in Windows Settings.\n" +
                         "4. If still blocked, check third-party antivirus firewall rules.";

        System.Windows.MessageBox.Show(helpMsg, "Firewall Help", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void GenerateQrCode()
    {
        try
        {
            byte[] qrBytes = _pairingService.GenerateQrCodePng(LocalIPAddress, Port, PairingPIN);

            _dispatcher.Invoke(() =>
            {
                BitmapImage image = new BitmapImage();
                using (MemoryStream ms = new MemoryStream(qrBytes))
                {
                    image.BeginInit();
                    image.CacheOption = BitmapCacheOption.OnLoad;
                    image.StreamSource = ms;
                    image.EndInit();
                }
                image.Freeze();
                QrCodeImage = image;
                Log("QR Code generated successfully.");
            });
        }
        catch (Exception ex)
        {
            Log($"Error generating QR Code: {ex.Message}");
        }
    }

    private void Log(string message)
    {
        _dispatcher.BeginInvoke(new Action(() =>
        {
            Logs.Insert(0, $"[{DateTime.Now:HH:mm:ss}] {message}");
            while (Logs.Count > 50)
            {
                Logs.RemoveAt(Logs.Count - 1);
            }
        }));
    }

    private void UpdateReceiverState()
    {
        _dispatcher.BeginInvoke(new Action(() =>
        {
            ReceiverStatus = IsReceiverRunning ? "Running" : "Stopped";
            OnPropertyChanged(nameof(IsReceiverRunning));
            CommandManager.InvalidateRequerySuggested();
        }));
    }

    private void PhoneConnected(string phoneName)
    {
        _dispatcher.BeginInvoke(new Action(() =>
        {
            ConnectionStatus = "Connected";
            ConnectedPhoneName = phoneName;
            OnPropertyChanged(nameof(IsPhoneConnected));
            CommandManager.InvalidateRequerySuggested();
        }));
    }

    private void PhoneDisconnected()
    {
        _dispatcher.BeginInvoke(new Action(() =>
        {
            ConnectionStatus = "Waiting";
            ConnectedPhoneName = "None";
            OnPropertyChanged(nameof(IsPhoneConnected));
            CommandManager.InvalidateRequerySuggested();
        }));
    }

    private void CommandReceived(string commandDesc)
    {
        _dispatcher.BeginInvoke(new Action(() =>
        {
            LastCommand = commandDesc;
            CommandCount++;
            Log($"Executed: {commandDesc}");
        }));
    }

    protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    protected bool SetField<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }
}

public class RelayCommand : ICommand
{
    private readonly Action _execute;
    private readonly Func<bool>? _canExecute;

    public RelayCommand(Action execute, Func<bool>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter) => _canExecute == null || _canExecute();
    public void Execute(object? parameter) => _execute();

    public event EventHandler? CanExecuteChanged
    {
        add => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }
}
