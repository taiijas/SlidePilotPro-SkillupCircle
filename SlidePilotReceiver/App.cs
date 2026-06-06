using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using SlidePilotReceiver.Services;
using SlidePilotReceiver.ViewModels;
using Color = System.Windows.Media.Color;
using ColorConverter = System.Windows.Media.ColorConverter;
using TextBox = System.Windows.Controls.TextBox;
using Button = System.Windows.Controls.Button;
using FontFamily = System.Windows.Media.FontFamily;
using Cursors = System.Windows.Input.Cursors;

namespace SlidePilotReceiver;

public class App : System.Windows.Application
{
    private WebSocketReceiverService? _webSocketService;
    private PairingService? _pairingService;
    private NetworkInfoService? _networkInfoService;
    private FirewallHelper? _firewallHelper;
    private TrayService? _trayService;

    private MainViewModel? _viewModel;
    private MainWindow? _mainWindow;

    public App()
    {
        ShutdownMode = ShutdownMode.OnExplicitShutdown;
    }

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // 1. Initialize Styles in Application Resources
        InitializeGlobalResources();

        // 2. Initialize Services
        _webSocketService = new WebSocketReceiverService();
        _pairingService = new PairingService();
        _networkInfoService = new NetworkInfoService();
        _firewallHelper = new FirewallHelper();

        // 3. Initialize ViewModel
        _viewModel = new MainViewModel(_webSocketService, _pairingService, _networkInfoService, _firewallHelper);

        // 4. Initialize Window
        _mainWindow = new MainWindow(_viewModel);

        // 5. Initialize Tray Service
        _trayService = new TrayService(
            onRestore: RestoreWindow,
            onStart: () => _viewModel.StartReceiver(),
            onStop: () => _viewModel.StopReceiver(),
            onExit: ShutdownApp,
            isReceiverRunning: () => _webSocketService.IsRunning
        );
        _trayService.Initialize();

        // Update tray menu when server status updates
        _webSocketService.OnStatusChanged += () => _trayService.UpdateContextMenu();

        // 6. Show Main Window on Startup
        _mainWindow.Show();
    }

    private void InitializeGlobalResources()
    {
        Style fieldLabelStyle = new Style(typeof(TextBlock));
        fieldLabelStyle.Setters.Add(new Setter(TextBlock.ForegroundProperty, new SolidColorBrush((Color)ColorConverter.ConvertFromString("#A1A1AA"))));
        fieldLabelStyle.Setters.Add(new Setter(TextBlock.FontWeightProperty, FontWeights.Medium));
        fieldLabelStyle.Setters.Add(new Setter(TextBlock.FontSizeProperty, 12.0));
        fieldLabelStyle.Setters.Add(new Setter(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center));
        fieldLabelStyle.Setters.Add(new Setter(TextBlock.MarginProperty, new Thickness(0, 0, 0, 4)));
        Resources.Add("FieldLabel", fieldLabelStyle);

        Style fieldValueStyle = new Style(typeof(TextBox));
        fieldValueStyle.Setters.Add(new Setter(TextBox.BackgroundProperty, new SolidColorBrush((Color)ColorConverter.ConvertFromString("#18181C"))));
        fieldValueStyle.Setters.Add(new Setter(TextBox.ForegroundProperty, new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F4F4F5"))));
        fieldValueStyle.Setters.Add(new Setter(TextBox.BorderBrushProperty, new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2A2A30"))));
        fieldValueStyle.Setters.Add(new Setter(TextBox.BorderThicknessProperty, new Thickness(1)));
        fieldValueStyle.Setters.Add(new Setter(TextBox.PaddingProperty, new Thickness(8, 6, 8, 6)));
        fieldValueStyle.Setters.Add(new Setter(TextBox.FontSizeProperty, 14.0));
        fieldValueStyle.Setters.Add(new Setter(TextBox.FontFamilyProperty, new FontFamily("Consolas")));
        fieldValueStyle.Setters.Add(new Setter(TextBox.IsReadOnlyProperty, true));
        fieldValueStyle.Setters.Add(new Setter(TextBox.MarginProperty, new Thickness(0, 0, 0, 10)));
        Resources.Add("FieldValue", fieldValueStyle);

        Style baseBtnStyle = new Style(typeof(Button));
        baseBtnStyle.Setters.Add(new Setter(Button.FontWeightProperty, FontWeights.SemiBold));
        baseBtnStyle.Setters.Add(new Setter(Button.HeightProperty, 38.0));
        baseBtnStyle.Setters.Add(new Setter(Button.FontSizeProperty, 13.0));
        baseBtnStyle.Setters.Add(new Setter(Button.CursorProperty, Cursors.Hand));
        baseBtnStyle.Setters.Add(new Setter(Button.MarginProperty, new Thickness(0, 0, 8, 0)));
        Resources.Add("BaseBtn", baseBtnStyle);
    }

    public void RestoreWindow()
    {
        if (_mainWindow != null)
        {
            _mainWindow.Show();
            if (_mainWindow.WindowState == WindowState.Minimized)
            {
                _mainWindow.WindowState = WindowState.Normal;
            }
            _mainWindow.Activate();
        }
    }

    public void ShowMinimizeToTrayNotification()
    {
        _trayService?.ShowNotification("Minimized to Tray", "SlidePilot Receiver is still running in the background.");
    }

    public void ShutdownApp()
    {
        _webSocketService?.Stop();
        _trayService?.Dispose();
        _mainWindow?.ExplicitExit();
        Shutdown();
    }
}
