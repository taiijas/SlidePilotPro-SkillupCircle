import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _showLogs = false;
  bool _showDiagnostics = false;

  void _triggerHaptic(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticFeedback) {
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Controller'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Panel
            _buildStatusPanel(context, btProvider),
            const SizedBox(height: 20),

            // If permissions are missing, show Permission Banner
            if (!btProvider.hasPermissionsState) ...[
              _buildPermissionRequestCard(context, btProvider),
              const SizedBox(height: 20),
            ],

            // If HID Profile is unsupported, show warning message
            if (btProvider.hasPermissionsState && !btProvider.isHidSupported) ...[
              _buildHidUnsupportedCard(context),
              const SizedBox(height: 20),
            ],

            // Host Connection State / Paired Devices
            if (btProvider.hasPermissionsState && btProvider.isHidSupported) ...[
              if (btProvider.connectionState == 2 && btProvider.connectedDeviceAddress != null)
                _buildConnectedDeviceCard(context, btProvider)
              else if (btProvider.connectionState == 1)
                _buildConnectingCard(context)
              else ...[
                // Last connected device
                if (btProvider.lastDeviceAddress != null) ...[
                  _buildLastConnectedCard(context, btProvider),
                  const SizedBox(height: 20),
                ],

                // Paired devices list
                _buildPairedDevicesHeader(context, btProvider),
                const SizedBox(height: 8),
                _buildPairedDevicesList(context, btProvider),
              ],
              const SizedBox(height: 20),
            ],

            // System Actions: Open Bluetooth Settings & Diagnostics
            _buildSystemActionsCard(context, btProvider),
            const SizedBox(height: 20),

            // Diagnostics Results Panel
            if (_showDiagnostics) ...[
              _buildDiagnosticsPanel(context, btProvider),
              const SizedBox(height: 20),
            ],

            // Debug Logs Console
            if (_showLogs) ...[
              _buildLogsConsole(context, btProvider),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel(BuildContext context, BluetoothProvider provider) {
    Color getBluetoothColor() {
      if (!provider.hasPermissionsState) return Colors.amber;
      return provider.isBluetoothEnabled ? AppTheme.success : AppTheme.error;
    }

    String getBluetoothText() {
      if (!provider.hasPermissionsState) return 'Permissions Missing';
      return provider.isBluetoothEnabled ? 'Enabled' : 'Disabled';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              context,
              'Bluetooth System',
              getBluetoothText(),
              getBluetoothColor(),
            ),
            const Divider(color: AppTheme.borderCol, height: 20),
            _buildStatusRow(
              context,
              'Android HID Profile',
              provider.isHidSupported ? 'Available' : 'Unavailable',
              provider.isHidSupported ? AppTheme.success : AppTheme.error,
            ),
            const Divider(color: AppTheme.borderCol, height: 20),
            _buildStatusRow(
              context,
              'HID App Registration',
              provider.isAppRegistered ? 'Registered' : 'Not Registered',
              provider.isAppRegistered ? AppTheme.success : AppTheme.error,
            ),
            const Divider(color: AppTheme.borderCol, height: 20),
            _buildStatusRow(
              context,
              'Host Connection',
              provider.connectionState == 2 ? 'Connected' : 'Disconnected',
              provider.connectionState == 2 ? AppTheme.success : AppTheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionRequestCard(BuildContext context, BluetoothProvider provider) {
    return Card(
      color: Colors.amber.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.amber, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 12),
                Text(
                  'Permissions Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'SlidePilot Pro requires Bluetooth Connect, Scan, and Advertise permissions to communicate with your computer as an HID mouse or keyboard.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _triggerHaptic(context);
                  provider.requestPermissions();
                },
                child: const Text('GRANT BLUETOOTH PERMISSIONS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHidUnsupportedCard(BuildContext context) {
    return Card(
      color: AppTheme.error.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HID Profile Unsupported',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Your Android phone does not expose Bluetooth HID Device Profile. This app cannot work on this phone without HID support. Try another Android phone or OEM firmware.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard(BuildContext context, BluetoothProvider provider) {
    return Card(
      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), // Glassy Blue
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.accentBlue, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_connected, color: AppTheme.accentBlue, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONNECTED HOST',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.connectedDeviceName ?? 'Unknown Device',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        provider.connectedDeviceAddress ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!provider.isAppRegistered)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentBlue),
                          ),
                          onPressed: () {
                            _triggerHaptic(context);
                            provider.registerApp();
                          },
                          child: const Text('REGISTER APP', style: TextStyle(color: AppTheme.accentBlue)),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _triggerHaptic(context);
                        provider.disconnectDevice();
                      },
                      child: const Text('DISCONNECT'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.accentBlue),
            const SizedBox(height: 16),
            Text(
              'Connecting to host...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ensuring HID application is registered and starting connection proxy.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastConnectedCard(BuildContext context, BluetoothProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Previously Connected Device',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.history, color: AppTheme.textMuted, size: 28),
            title: Text(
              provider.lastDeviceName ?? 'Unknown Device',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(provider.lastDeviceAddress ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white38),
                  onPressed: () {
                    provider.forgetLastDevice();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(80, 40),
                  ),
                  onPressed: () {
                    _triggerHaptic(context);
                    provider.connectDevice(provider.lastDeviceAddress!);
                  },
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPairedDevicesHeader(BuildContext context, BluetoothProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Paired Devices',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        if (provider.isLoadingDevices)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentBlue),
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
            onPressed: () {
              provider.refreshDevices();
            },
          ),
      ],
    );
  }

  Widget _buildPairedDevicesList(BuildContext context, BluetoothProvider provider) {
    if (!provider.hasPermissionsState) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Grant permissions to fetch paired devices',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    if (!provider.isBluetoothEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Enable Bluetooth to see paired devices',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    if (provider.pairedDevices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            'No paired devices found.\nPair your phone with your computer in Bluetooth Settings first.',
            style: TextStyle(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.pairedDevices.length,
      separatorBuilder: (_, ___) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = provider.pairedDevices[index];
        final name = device['name'] ?? 'Unknown Device';
        final address = device['address'] ?? '';

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.laptop, color: Colors.white70),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(address),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(80, 40),
                backgroundColor: AppTheme.borderCol,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _triggerHaptic(context);
                provider.connectDevice(address);
              },
              child: const Text('Connect'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemActionsCard(BuildContext context, BluetoothProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderCol),
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.settings_bluetooth, size: 18),
                    label: const Text('OS SETTINGS', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _triggerHaptic(context);
                      provider.openBluetoothSettings();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderCol),
                      foregroundColor: AppTheme.accentBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('DIAGNOSTICS', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      _triggerHaptic(context);
                      await provider.runDiagnostics();
                      setState(() {
                        _showDiagnostics = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(_showLogs ? Icons.bug_report : Icons.bug_report_outlined,
                      color: _showLogs ? Colors.orangeAccent : Colors.white60),
                  onPressed: () {
                    _triggerHaptic(context);
                    setState(() {
                      _showLogs = !_showLogs;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsPanel(BuildContext context, BluetoothProvider provider) {
    final diag = provider.diagnosticsResult;
    if (diag.isEmpty) return const SizedBox();

    return Card(
      color: AppTheme.cardBg.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diagnostics Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentBlue,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _showDiagnostics = false;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            _buildDiagRow('Device Model', '${diag['manufacturer']} ${diag['device_model']}'),
            _buildDiagRow('Android Version', 'Android ${diag['android_version']} (API ${diag['api_level']})'),
            _buildDiagRow('Bluetooth Permissions', diag['bluetooth_permissions'] == true ? 'GRANTED' : 'MISSING',
                color: diag['bluetooth_permissions'] == true ? AppTheme.success : AppTheme.error),
            _buildDiagRow('Bluetooth Hardware ON', diag['bluetooth_enabled'] == true ? 'YES' : 'NO',
                color: diag['bluetooth_enabled'] == true ? AppTheme.success : AppTheme.error),
            _buildDiagRow('HID Device Profile available', diag['hid_profile_available'] == true ? 'YES' : 'NO',
                color: diag['hid_profile_available'] == true ? AppTheme.success : AppTheme.error),
            _buildDiagRow('HID App Registered', diag['hid_app_registered'] == true ? 'YES' : 'NO',
                color: diag['hid_app_registered'] == true ? AppTheme.success : AppTheme.error),
            _buildDiagRow('Paired Devices Count', '${diag['paired_devices_count']} devices'),
            const Divider(color: AppTheme.borderCol, height: 24),
            Text(
              'Interactive HID Tests',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sends test reports directly to isolate connection and HID registration status.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                _buildTestButton(
                  context,
                  Icons.arrow_forward,
                  'Right Arrow',
                  () => provider.sendKeyboardKey('', 'right_arrow'),
                ),
                _buildTestButton(
                  context,
                  Icons.arrow_back,
                  'Left Arrow',
                  () => provider.sendKeyboardKey('', 'left_arrow'),
                ),
                _buildTestButton(
                  context,
                  Icons.space_bar,
                  'Space',
                  () => provider.sendKeyboardKey('', 'space'),
                ),
                _buildTestButton(
                  context,
                  Icons.cancel_presentation,
                  'Esc',
                  () => provider.sendKeyboardKey('', 'escape'),
                ),
                _buildTestButton(
                  context,
                  Icons.keyboard_double_arrow_right,
                  'Mouse Right',
                  () => provider.sendMouseMove(20, 0),
                ),
                _buildTestButton(
                  context,
                  Icons.touch_app,
                  'Left Click',
                  () => provider.sendLeftClick(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardBg,
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.borderCol, width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      icon: Icon(icon, size: 16, color: AppTheme.accentBlue),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        _triggerHaptic(context);
        onPressed();
      },
    );
  }

  Widget _buildDiagRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsConsole(BuildContext context, BluetoothProvider provider) {
    return Card(
      color: Colors.black.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderCol, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Live Debug Logs',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      onPressed: () {
                        provider.clearLogs();
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                      onPressed: () {
                        setState(() {
                          _showLogs = false;
                        });
                      },
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(6),
              ),
              child: provider.logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs recorded yet.',
                        style: TextStyle(color: Colors.white30, fontFamily: 'monospace', fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: provider.logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            provider.logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.lightGreenAccent,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
