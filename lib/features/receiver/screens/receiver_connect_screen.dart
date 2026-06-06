import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/receiver_service.dart';
import '../../../core/theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class ReceiverConnectScreen extends StatefulWidget {
  const ReceiverConnectScreen({super.key});

  @override
  State<ReceiverConnectScreen> createState() => _ReceiverConnectScreenState();
}

class _ReceiverConnectScreenState extends State<ReceiverConnectScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '45678');
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController(text: 'Android Phone');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _pinController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.vibrate();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _scanQrCode() async {
    _triggerHaptic();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (!mounted) return;

    if (result != null && result is String) {
      try {
        final Map<String, dynamic> payload = jsonDecode(result);
        if (payload['app'] == 'SlidePilot' && payload['mode'] == 'receiver') {
          setState(() {
            _hostController.text = payload['host'] ?? '';
            _portController.text = (payload['port'] ?? 45678).toString();
            _pinController.text = payload['pin'] ?? '';
            _deviceNameController.text = payload['deviceName'] ?? 'Windows PC';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code scanned successfully! Details populated.'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          _showErrorSnackBar('Invalid QR: Not a SlidePilot Receiver QR Code.');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to parse QR code: $e');
      }
    }
  }

  void _connect(ReceiverService service) {
    _triggerHaptic();
    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();
    final pin = _pinController.text.trim();
    final devName = _deviceNameController.text.trim();

    if (host.isEmpty || portStr.isEmpty || pin.isEmpty) {
      _showErrorSnackBar('Host, Port, and PIN are required.');
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      _showErrorSnackBar('Port must be a valid integer.');
      return;
    }

    service.connectToReceiver(host, port, pin, devName.isEmpty ? 'Android Phone' : devName);
  }

  @override
  Widget build(BuildContext context) {
    final receiverService = Provider.of<ReceiverService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Windows'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Scan card
            _buildQrScanCard(),
            const SizedBox(height: 20),

            // Manual Connection Details card
            _buildManualConnectCard(receiverService),
            const SizedBox(height: 20),

            // Connection status and diagnostics
            _buildStatusAndDiagnosticsCard(receiverService),
            const SizedBox(height: 20),

            // Saved Receivers List
            _buildSavedReceiversCard(receiverService),
            const SizedBox(height: 20),

            // Logs Console
            _buildLogsConsole(receiverService),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppTheme.accentBlue, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Pairing QR Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Scan the QR code displayed on the Windows Receiver tray window to pair automatically.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('SCAN QR CODE'),
                onPressed: _scanQrCode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualConnectCard(ReceiverService service) {
    final isConnected = service.isConnected;
    final isConnecting = service.isConnecting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Connection Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hostController,
              enabled: !isConnected && !isConnecting,
              decoration: const InputDecoration(
                labelText: 'Receiver IP Address (Host)',
                hintText: 'e.g. 192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _portController,
                    enabled: !isConnected && !isConnecting,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _pinController,
                    enabled: !isConnected && !isConnecting,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Pairing PIN',
                      hintText: '6-digit PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceNameController,
              enabled: !isConnected && !isConnecting,
              decoration: const InputDecoration(
                labelText: 'Device Name (Optional)',
                hintText: 'e.g. My Android Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? AppTheme.error : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isConnecting
                          ? null
                          : () {
                              if (isConnected) {
                                _triggerHaptic();
                                service.disconnectReceiver();
                              } else {
                                _connect(service);
                              }
                            },
                      child: isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isConnected ? 'DISCONNECT' : 'CONNECT'),
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

  Widget _buildStatusAndDiagnosticsCard(ReceiverService service) {
    Color getStatusColor() {
      if (service.isConnecting || service.pairingStatus == 'Pairing') return Colors.amber;
      if (service.isConnected && service.pairingStatus == 'Paired') return AppTheme.success;
      return AppTheme.error;
    }

    String getStatusText() {
      if (service.isConnecting || service.pairingStatus == 'Pairing') return 'Pairing...';
      if (service.isConnected && service.pairingStatus == 'Paired') return 'Connected';
      return 'Disconnected';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection & Diagnostics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildDiagRow('Status', getStatusText(), getStatusColor()),
            const Divider(color: AppTheme.borderCol, height: 20),
            _buildDiagRow('Pairing Status', service.pairingStatus, getStatusColor()),
            if (service.isConnected && service.lastCommandSent != null) ...[
              const Divider(color: AppTheme.borderCol, height: 20),
              _buildDiagRow('Last Command', service.lastCommandSent!, AppTheme.textMuted),
            ],
            if (service.isConnected) ...[
              const Divider(color: AppTheme.borderCol, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Test Network Ping', style: TextStyle(fontSize: 13, color: Colors.white60)),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
                    icon: const Icon(Icons.network_ping, size: 18),
                    label: const Text('Send Ping'),
                    onPressed: () {
                      _triggerHaptic();
                      service.ping();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedReceiversCard(ReceiverService service) {
    if (service.savedReceivers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Receivers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.savedReceivers.length,
              separatorBuilder: (_, ___) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final receiver = service.savedReceivers[index];
                final host = receiver['host'] ?? '';
                final port = receiver['port'] ?? 45678;
                final pin = receiver['pin'] ?? '';
                final deviceName = receiver['deviceName'] ?? 'Windows PC';

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderCol),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.laptop, color: Colors.white70),
                    title: Text(
                      deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text('$host:$port'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () {
                            _triggerHaptic();
                            service.deleteSavedReceiver(host, port);
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(60, 36),
                            backgroundColor: AppTheme.borderCol,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: service.isConnected || service.isConnecting
                              ? null
                              : () {
                                  _triggerHaptic();
                                  setState(() {
                                    _hostController.text = host;
                                    _portController.text = port.toString();
                                    _pinController.text = pin;
                                    _deviceNameController.text = deviceName;
                                  });
                                  service.connectToReceiver(host, port, pin, deviceName);
                                },
                          child: const Text('Connect', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsConsole(ReceiverService service) {
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
                    Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Receiver Connection Logs',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    _triggerHaptic();
                    service.clearLogs();
                  },
                  child: const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
              child: service.logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs recorded yet.',
                        style: TextStyle(color: Colors.white30, fontFamily: 'monospace', fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: service.logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            service.logs[index],
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
