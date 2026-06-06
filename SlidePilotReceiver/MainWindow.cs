using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Media;
using SlidePilotReceiver.ViewModels;
using Button = System.Windows.Controls.Button;
using Image = System.Windows.Controls.Image;
using Color = System.Windows.Media.Color;
using ColorConverter = System.Windows.Media.ColorConverter;
using TextBox = System.Windows.Controls.TextBox;
using ListBox = System.Windows.Controls.ListBox;
using Binding = System.Windows.Data.Binding;
using Brushes = System.Windows.Media.Brushes;
using FontFamily = System.Windows.Media.FontFamily;
using Orientation = System.Windows.Controls.Orientation;
using Cursors = System.Windows.Input.Cursors;

namespace SlidePilotReceiver;

public class MainWindow : Window
{
    private bool _isExplicitExit = false;
    private readonly MainViewModel _viewModel;

    // Badges controls
    private Border? _serverStatusBadge;
    private TextBlock? _serverStatusText;
    private Border? _phoneStatusBadge;
    private TextBlock? _phoneStatusText;

    // QR controls
    private TextBlock? _qrPlaceholderText;
    private Image? _qrCodeImageControl;

    public MainWindow(MainViewModel viewModel)
    {
        _viewModel = viewModel;
        DataContext = _viewModel;

        Title = "SlidePilot Receiver";
        Height = 620;
        Width = 980;
        Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#0A0A0C"));
        Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F4F4F5"));
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        ResizeMode = ResizeMode.CanMinimize;
        BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1F1F23"));
        BorderThickness = new Thickness(1);

        InitializeUI();

        _viewModel.PropertyChanged += OnViewModelPropertyChanged;
        Closing += MainWindow_Closing;

        // Trigger initial badge values
        UpdateReceiverBadge();
        UpdatePhoneBadge();
        UpdateQrPlaceholder();
    }

    public void ExplicitExit()
    {
        _isExplicitExit = true;
        Close();
    }

    private void MainWindow_Closing(object? sender, CancelEventArgs e)
    {
        if (!_isExplicitExit)
        {
            e.Cancel = true;
            Hide();
            (System.Windows.Application.Current as App)?.ShowMinimizeToTrayNotification();
        }
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(MainViewModel.ReceiverStatus))
        {
            UpdateReceiverBadge();
        }
        else if (e.PropertyName == nameof(MainViewModel.ConnectionStatus))
        {
            UpdatePhoneBadge();
        }
        else if (e.PropertyName == nameof(MainViewModel.QrCodeImage))
        {
            UpdateQrPlaceholder();
        }
    }

    private void InitializeUI()
    {
        Grid mainGrid = new Grid { Margin = new Thickness(18) };
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Header
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // Content
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Footer

        // ==========================================
        // 1. HEADER BAR
        // ==========================================
        Grid headerGrid = new Grid { Margin = new Thickness(0, 0, 0, 16) };
        headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Brand
        StackPanel brandPanel = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = System.Windows.VerticalAlignment.Center };
        Border logoBorder = new Border
        {
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2563EB")),
            Width = 32,
            Height = 32,
            Margin = new Thickness(0, 0, 10, 0)
        };
        logoBorder.Child = new TextBlock
        {
            Text = "SP",
            Foreground = Brushes.White,
            FontWeight = FontWeights.Bold,
            FontSize = 15,
            HorizontalAlignment = System.Windows.HorizontalAlignment.Center,
            VerticalAlignment = System.Windows.VerticalAlignment.Center
        };
        brandPanel.Children.Add(logoBorder);

        StackPanel titlePanel = new StackPanel();
        titlePanel.Children.Add(new TextBlock { Text = "SlidePilot Receiver", FontWeight = FontWeights.Bold, FontSize = 18, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F4F4F5")) });
        
        TextBlock versionText = new TextBlock { FontSize = 11, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#71717A")) };
        BindingOperations.SetBinding(versionText, TextBlock.TextProperty, new Binding("AppVersion") { StringFormat = "Version {0}" });
        titlePanel.Children.Add(versionText);
        brandPanel.Children.Add(titlePanel);
        headerGrid.Children.Add(brandPanel);
        Grid.SetColumn(brandPanel, 0);

        // Status Badges
        StackPanel badgesPanel = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = System.Windows.VerticalAlignment.Center };
        
        _serverStatusBadge = new Border { CornerRadius = new CornerRadius(12), Padding = new Thickness(10, 5, 10, 5), Margin = new Thickness(0, 0, 8, 0) };
        _serverStatusText = new TextBlock { Foreground = Brushes.White, FontWeight = FontWeights.Bold, FontSize = 11 };
        _serverStatusBadge.Child = _serverStatusText;
        badgesPanel.Children.Add(_serverStatusBadge);

        _phoneStatusBadge = new Border { CornerRadius = new CornerRadius(12), Padding = new Thickness(10, 5, 10, 5) };
        _phoneStatusText = new TextBlock { Foreground = Brushes.White, FontWeight = FontWeights.Bold, FontSize = 11 };
        _phoneStatusBadge.Child = _phoneStatusText;
        badgesPanel.Children.Add(_phoneStatusBadge);

        headerGrid.Children.Add(badgesPanel);
        Grid.SetColumn(badgesPanel, 1);

        mainGrid.Children.Add(headerGrid);
        Grid.SetRow(headerGrid, 0);

        // ==========================================
        // 2. MAIN CONTENT (Left: Pairing, Right: Stats/Logs)
        // ==========================================
        Grid contentGrid = new Grid { Margin = new Thickness(0, 0, 0, 16) };
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(340) });
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        // Left Card (Pairing details)
        Border leftCard = CreatePanelCard();
        leftCard.Margin = new Thickness(0, 0, 14, 0);
        Grid.SetColumn(leftCard, 0);
        contentGrid.Children.Add(leftCard);

        Grid leftGrid = new Grid();
        leftGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        leftGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        leftGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        leftCard.Child = leftGrid;

        leftGrid.Children.Add(new TextBlock { Text = "Pairing details", FontWeight = FontWeights.Bold, FontSize = 14, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E4E4E7")), Margin = new Thickness(0, 0, 0, 12) });

        // QR Code Display
        Border qrBorder = new Border
        {
            Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#0C0C0E")),
            BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1C1C1F")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16),
            Height = 230,
            Width = 230,
            HorizontalAlignment = System.Windows.HorizontalAlignment.Center,
            VerticalAlignment = System.Windows.VerticalAlignment.Center
        };
        Grid qrContentGrid = new Grid();
        _qrPlaceholderText = new TextBlock
        {
            Text = "Start Receiver to display pairing QR Code",
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#52525B")),
            TextWrapping = TextWrapping.Wrap,
            TextAlignment = TextAlignment.Center,
            VerticalAlignment = System.Windows.VerticalAlignment.Center,
            HorizontalAlignment = System.Windows.HorizontalAlignment.Center,
            FontSize = 13
        };
        _qrCodeImageControl = new Image { Stretch = Stretch.Uniform };
        RenderOptions.SetBitmapScalingMode(_qrCodeImageControl, BitmapScalingMode.NearestNeighbor);
        BindingOperations.SetBinding(_qrCodeImageControl, Image.SourceProperty, new Binding("QrCodeImage"));

        qrContentGrid.Children.Add(_qrPlaceholderText);
        qrContentGrid.Children.Add(_qrCodeImageControl);
        qrBorder.Child = qrContentGrid;
        leftGrid.Children.Add(qrBorder);
        Grid.SetRow(qrBorder, 1);

        // Connection metadata fields
        StackPanel metadataPanel = new StackPanel { Margin = new Thickness(0, 12, 0, 0) };
        Grid.SetRow(metadataPanel, 2);
        leftGrid.Children.Add(metadataPanel);

        // IP Field
        Grid ipGrid = new Grid();
        ipGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        ipGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        
        StackPanel ipSubPanel = new StackPanel();
        ipSubPanel.Children.Add(new TextBlock { Text = "IP ADDRESS", Style = (Style)FindResource("FieldLabel") });
        TextBox ipBox = new TextBox { Style = (Style)FindResource("FieldValue") };
        BindingOperations.SetBinding(ipBox, TextBox.TextProperty, new Binding("LocalIPAddress") { Mode = BindingMode.OneWay });
        ipSubPanel.Children.Add(ipBox);
        ipGrid.Children.Add(ipSubPanel);
        Grid.SetColumn(ipSubPanel, 0);

        Button copyBtn = CreateButton("Copy", _viewModel.CopyIPCommand, "secondary");
        copyBtn.Height = 31;
        copyBtn.Width = 55;
        copyBtn.VerticalAlignment = System.Windows.VerticalAlignment.Bottom;
        copyBtn.Margin = new Thickness(8, 0, 0, 10);
        ipGrid.Children.Add(copyBtn);
        Grid.SetColumn(copyBtn, 1);
        metadataPanel.Children.Add(ipGrid);

        // Port & PIN fields
        Grid portPinGrid = new Grid();
        portPinGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        portPinGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        StackPanel portPanel = new StackPanel { Margin = new Thickness(0, 0, 8, 0) };
        portPanel.Children.Add(new TextBlock { Text = "PORT", Style = (Style)FindResource("FieldLabel") });
        TextBox portBox = new TextBox { Style = (Style)FindResource("FieldValue") };
        BindingOperations.SetBinding(portBox, TextBox.TextProperty, new Binding("Port") { Mode = BindingMode.OneWay });
        portPanel.Children.Add(portBox);
        portPinGrid.Children.Add(portPanel);
        Grid.SetColumn(portPanel, 0);

        StackPanel pinPanel = new StackPanel { Margin = new Thickness(8, 0, 0, 0) };
        pinPanel.Children.Add(new TextBlock { Text = "PAIRING PIN", Style = (Style)FindResource("FieldLabel") });
        TextBox pinBox = new TextBox { Style = (Style)FindResource("FieldValue"), FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#3B82F6")) };
        BindingOperations.SetBinding(pinBox, TextBox.TextProperty, new Binding("PairingPIN") { Mode = BindingMode.OneWay });
        pinPanel.Children.Add(pinBox);
        portPinGrid.Children.Add(pinPanel);
        Grid.SetColumn(pinPanel, 1);
        metadataPanel.Children.Add(portPinGrid);

        // Right side (Stats & Log Console)
        Grid rightGrid = new Grid();
        rightGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        rightGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        Grid.SetColumn(rightGrid, 1);
        contentGrid.Children.Add(rightGrid);

        // Stats card (Row 0)
        Border statsCard = CreatePanelCard();
        rightGrid.Children.Add(statsCard);
        Grid.SetRow(statsCard, 0);

        Grid statsGrid = new Grid();
        statsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        statsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.5, GridUnitType.Star) });
        statsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        statsCard.Child = statsGrid;

        // Stat 1: Connected Phone
        StackPanel phonePanel = new StackPanel();
        phonePanel.Children.Add(new TextBlock { Text = "CONNECTED PHONE", Style = (Style)FindResource("FieldLabel") });
        TextBlock phoneNameText = new TextBlock { FontWeight = FontWeights.Bold, FontSize = 15, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F4F4F5")) };
        BindingOperations.SetBinding(phoneNameText, TextBlock.TextProperty, new Binding("ConnectedPhoneName"));
        phonePanel.Children.Add(phoneNameText);
        Button disconnectBtn = CreateButton("Disconnect", _viewModel.DisconnectPhoneCommand, "secondary");
        disconnectBtn.Margin = new Thickness(0, 8, 0, 0);
        disconnectBtn.Height = 28;
        disconnectBtn.Width = 90;
        disconnectBtn.HorizontalAlignment = System.Windows.HorizontalAlignment.Left;
        disconnectBtn.FontSize = 11;
        phonePanel.Children.Add(disconnectBtn);
        statsGrid.Children.Add(phonePanel);
        Grid.SetColumn(phonePanel, 0);

        // Stat 2: Last received command (wrapped in Border for custom styling)
        Border lastCmdBorder = new Border
        {
            BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1C1C1F")),
            BorderThickness = new Thickness(1, 0, 1, 0),
            Padding = new Thickness(16, 0, 16, 0),
            Margin = new Thickness(10, 0, 10, 0)
        };
        StackPanel lastCmdPanel = new StackPanel();
        lastCmdPanel.Children.Add(new TextBlock { Text = "LAST RECEIVED COMMAND", Style = (Style)FindResource("FieldLabel") });
        TextBlock lastCmdText = new TextBlock { FontWeight = FontWeights.Bold, FontSize = 14, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#10B981")) };
        BindingOperations.SetBinding(lastCmdText, TextBlock.TextProperty, new Binding("LastCommand"));
        lastCmdPanel.Children.Add(lastCmdText);
        lastCmdBorder.Child = lastCmdPanel;
        statsGrid.Children.Add(lastCmdBorder);
        Grid.SetColumn(lastCmdBorder, 1);

        // Stat 3: Command count stats
        StackPanel countPanel = new StackPanel { HorizontalAlignment = System.Windows.HorizontalAlignment.Center };
        countPanel.Children.Add(new TextBlock { Text = "COMMAND COUNT", Style = (Style)FindResource("FieldLabel"), HorizontalAlignment = System.Windows.HorizontalAlignment.Center });
        TextBlock countText = new TextBlock { FontWeight = FontWeights.Bold, FontSize = 26, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#3B82F6")), HorizontalAlignment = System.Windows.HorizontalAlignment.Center };
        BindingOperations.SetBinding(countText, TextBlock.TextProperty, new Binding("CommandCount"));
        countPanel.Children.Add(countText);
        statsGrid.Children.Add(countPanel);
        Grid.SetColumn(countPanel, 2);

        // Logs console card (Row 1)
        Border logsCard = CreatePanelCard();
        rightGrid.Children.Add(logsCard);
        Grid.SetRow(logsCard, 1);

        Grid logsLayoutGrid = new Grid();
        logsLayoutGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        logsLayoutGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        logsCard.Child = logsLayoutGrid;

        logsLayoutGrid.Children.Add(new TextBlock { Text = "Activity Log", FontWeight = FontWeights.Bold, FontSize = 14, Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E4E4E7")), Margin = new Thickness(0, 0, 0, 8) });

        Border terminalBorder = new Border
        {
            Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#050506")),
            BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1C1C1F")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(12)
        };
        ListBox logsList = new ListBox
        {
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#10B981")),
            FontSize = 11,
            FontFamily = new FontFamily("Consolas")
        };
        BindingOperations.SetBinding(logsList, ItemsControl.ItemsSourceProperty, new Binding("Logs"));
        
        // Disable generic ListBox item highlighting styling
        Style itemStyle = new Style(typeof(ListBoxItem));
        itemStyle.Setters.Add(new Setter(PaddingProperty, new Thickness(2)));
        itemStyle.Setters.Add(new Setter(BackgroundProperty, Brushes.Transparent));
        itemStyle.Setters.Add(new Setter(FocusableProperty, false));
        logsList.ItemContainerStyle = itemStyle;

        terminalBorder.Child = logsList;
        logsLayoutGrid.Children.Add(terminalBorder);
        Grid.SetRow(terminalBorder, 1);

        mainGrid.Children.Add(contentGrid);
        Grid.SetRow(contentGrid, 1);

        // ==========================================
        // 3. BOTTOM FOOTER CONTROLS BAR
        // ==========================================
        Border footerBorder = new Border
        {
            Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#111113")),
            BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#202024")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(12)
        };
        Grid.SetRow(footerBorder, 2);
        mainGrid.Children.Add(footerBorder);

        Grid footerGrid = new Grid();
        footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        footerBorder.Child = footerGrid;

        // Start/Stop/Regen controls
        StackPanel serverOpsPanel = new StackPanel { Orientation = Orientation.Horizontal };
        Button startBtn = CreateButton("Start Receiver", _viewModel.StartCommand, "primary");
        startBtn.Width = 120;
        Button stopBtn = CreateButton("Stop Receiver", _viewModel.StopCommand, "danger");
        stopBtn.Width = 120;
        Button regenBtn = CreateButton("Regenerate PIN", _viewModel.RegeneratePinCommand, "secondary");
        regenBtn.Width = 120;
        
        serverOpsPanel.Children.Add(startBtn);
        serverOpsPanel.Children.Add(stopBtn);
        serverOpsPanel.Children.Add(regenBtn);
        footerGrid.Children.Add(serverOpsPanel);
        Grid.SetColumn(serverOpsPanel, 0);

        // Warning Text
        TextBlock warningText = new TextBlock
        {
            Text = "Allow SlidePilot Receiver on Private Networks so your phone can connect over Wi-Fi.",
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#71717A")),
            VerticalAlignment = System.Windows.VerticalAlignment.Center,
            HorizontalAlignment = System.Windows.HorizontalAlignment.Center,
            FontSize = 11,
            FontStyle = FontStyles.Italic
        };
        footerGrid.Children.Add(warningText);
        Grid.SetColumn(warningText, 1);

        // Support controls
        StackPanel supportPanel = new StackPanel { Orientation = Orientation.Horizontal };
        Button fwBtn = CreateButton("Firewall Help", _viewModel.OpenFirewallHelpCommand, "secondary");
        fwBtn.Width = 110;
        Button exitBtn = CreateButton("Exit", _viewModel.ExitCommand, "secondary");
        exitBtn.Width = 80;
        exitBtn.Margin = new Thickness(0);

        supportPanel.Children.Add(fwBtn);
        supportPanel.Children.Add(exitBtn);
        footerGrid.Children.Add(supportPanel);
        Grid.SetColumn(supportPanel, 2);

        Content = mainGrid;
    }

    private Border CreatePanelCard()
    {
        return new Border
        {
            Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#111113")),
            BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#202024")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(16),
            Margin = new Thickness(0, 0, 0, 12)
        };
    }

    private Button CreateButton(string content, ICommand command, string type)
    {
        Button button = new Button
        {
            Content = content,
            Command = command,
            FontWeight = FontWeights.SemiBold,
            Height = 38,
            FontSize = 13,
            Cursor = Cursors.Hand,
            Margin = new Thickness(0, 0, 8, 0),
            BorderThickness = new Thickness(0)
        };

        Color bg = type switch
        {
            "primary" => (Color)ColorConverter.ConvertFromString("#2563EB"),
            "danger" => (Color)ColorConverter.ConvertFromString("#DC2626"),
            _ => (Color)ColorConverter.ConvertFromString("#1E1E22")
        };

        Color fg = type switch
        {
            "secondary" => (Color)ColorConverter.ConvertFromString("#E4E4E7"),
            _ => Colors.White
        };

        button.Background = new SolidColorBrush(bg);
        button.Foreground = new SolidColorBrush(fg);

        if (type == "secondary")
        {
            button.BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2D2D34"));
            button.BorderThickness = new Thickness(1);
        }

        // Mouse Hover behaviors
        button.MouseEnter += (s, e) =>
        {
            if (button.IsEnabled)
            {
                button.Background = new SolidColorBrush(type switch
                {
                    "primary" => (Color)ColorConverter.ConvertFromString("#3B82F6"),
                    "danger" => (Color)ColorConverter.ConvertFromString("#EF4444"),
                    _ => (Color)ColorConverter.ConvertFromString("#2D2D34")
                });
            }
        };

        button.MouseLeave += (s, e) =>
        {
            if (button.IsEnabled)
            {
                button.Background = new SolidColorBrush(bg);
            }
        };

        // Enable state change behaviors
        button.IsEnabledChanged += (s, e) =>
        {
            if (!button.IsEnabled)
            {
                button.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#111113"));
                button.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#52525B"));
                if (type == "secondary") button.BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#202024"));
            }
            else
            {
                button.Background = new SolidColorBrush(bg);
                button.Foreground = new SolidColorBrush(fg);
                if (type == "secondary") button.BorderBrush = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2D2D34"));
            }
        };

        // Set style template support for disabled state
        button.Style = (Style)FindResource("BaseBtn");

        return button;
    }

    private void UpdateReceiverBadge()
    {
        if (_serverStatusBadge == null || _serverStatusText == null) return;

        string status = _viewModel.ReceiverStatus;
        _serverStatusText.Text = $"Server: {status}";

        if (status == "Running")
        {
            _serverStatusBadge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#15803D"));
        }
        else
        {
            _serverStatusBadge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#27272A"));
        }
    }

    private void UpdatePhoneBadge()
    {
        if (_phoneStatusBadge == null || _phoneStatusText == null) return;

        string status = _viewModel.ConnectionStatus;
        _phoneStatusText.Text = $"Phone: {status}";

        if (status == "Connected")
        {
            _phoneStatusBadge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1D4ED8"));
        }
        else if (status == "Waiting")
        {
            _phoneStatusBadge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#D97706"));
        }
        else
        {
            _phoneStatusBadge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#27272A"));
        }
    }

    private void UpdateQrPlaceholder()
    {
        if (_qrPlaceholderText == null || _qrCodeImageControl == null) return;

        if (_viewModel.QrCodeImage == null)
        {
            _qrPlaceholderText.Visibility = Visibility.Visible;
            _qrCodeImageControl.Visibility = Visibility.Collapsed;
        }
        else
        {
            _qrPlaceholderText.Visibility = Visibility.Collapsed;
            _qrCodeImageControl.Visibility = Visibility.Visible;
        }
    }
}
