using System;
using System.Drawing;
using System.Windows.Forms;

namespace SlidePilotReceiver.Services;

public class TrayService : IDisposable
{
    private NotifyIcon? _notifyIcon;
    private readonly Action _onRestore;
    private readonly Action _onStart;
    private readonly Action _onStop;
    private readonly Action _onExit;
    private readonly Func<bool> _isReceiverRunning;

    public TrayService(Action onRestore, Action onStart, Action onStop, Action onExit, Func<bool> isReceiverRunning)
    {
        _onRestore = onRestore;
        _onStart = onStart;
        _onStop = onStop;
        _onExit = onExit;
        _isReceiverRunning = isReceiverRunning;
    }

    public void Initialize()
    {
        _notifyIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "SlidePilot Receiver",
            Visible = true
        };

        _notifyIcon.DoubleClick += (s, e) => _onRestore();

        UpdateContextMenu();
    }

    public void UpdateContextMenu()
    {
        if (_notifyIcon == null) return;

        var contextMenu = new ContextMenuStrip();

        var restoreItem = new ToolStripMenuItem("Restore Window", null, (s, e) => _onRestore());
        contextMenu.Items.Add(restoreItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        bool running = _isReceiverRunning();

        var startItem = new ToolStripMenuItem("Start Receiver", null, (s, e) => _onStart()) { Enabled = !running };
        contextMenu.Items.Add(startItem);

        var stopItem = new ToolStripMenuItem("Stop Receiver", null, (s, e) => _onStop()) { Enabled = running };
        contextMenu.Items.Add(stopItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        var exitItem = new ToolStripMenuItem("Exit", null, (s, e) => _onExit());
        contextMenu.Items.Add(exitItem);

        _notifyIcon.ContextMenuStrip = contextMenu;
    }

    public void ShowNotification(string title, string text)
    {
        _notifyIcon?.ShowBalloonTip(3000, title, text, ToolTipIcon.Info);
    }

    public void Dispose()
    {
        if (_notifyIcon != null)
        {
            _notifyIcon.Visible = false;
            _notifyIcon.Dispose();
            _notifyIcon = null;
        }
    }
}
