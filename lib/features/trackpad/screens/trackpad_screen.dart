import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../bluetooth/providers/bluetooth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class TrackpadScreen extends StatefulWidget {
  const TrackpadScreen({super.key});

  @override
  State<TrackpadScreen> createState() => _TrackpadScreenState();
}

class _TrackpadScreenState extends State<TrackpadScreen> {
  Offset _lastFocalPoint = Offset.zero;
  int _pointerCount = 0;

  void _triggerHaptic(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticFeedback) {
      HapticFeedback.vibrate();
    }
  }

  void _sendLeftClick(BluetoothProvider btProvider) async {
    _triggerHaptic(context);
    await btProvider.sendMouseButton(0, true);  // Left down
    await Future.delayed(const Duration(milliseconds: 30));
    await btProvider.sendMouseButton(0, false); // Left up
  }

  void _sendRightClick(BluetoothProvider btProvider) async {
    _triggerHaptic(context);
    await btProvider.sendMouseButton(1, true);  // Right down
    await Future.delayed(const Duration(milliseconds: 30));
    await btProvider.sendMouseButton(1, false); // Right up
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = Provider.of<BluetoothProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final isConnected = btProvider.hostConnectionState == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wireless Trackpad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                isConnected ? 'CONNECTED' : 'DISCONNECTED',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              backgroundColor: isConnected ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2),
              side: BorderSide(color: isConnected ? AppTheme.success : AppTheme.error),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Trackpad Area
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _pointerCount = details.pointerCount;
                  _lastFocalPoint = details.localFocalPoint;
                },
                onScaleUpdate: (details) {
                  if (details.pointerCount != _pointerCount) {
                    _pointerCount = details.pointerCount;
                    _lastFocalPoint = details.localFocalPoint;
                    return;
                  }

                  if (!isConnected) return;

                  final delta = details.localFocalPoint - _lastFocalPoint;
                  _lastFocalPoint = details.localFocalPoint;

                  if (_pointerCount == 1) {
                    // Mouse Move
                    final double dx = delta.dx * settings.pointerSensitivity;
                    final double dy = delta.dy * settings.pointerSensitivity;

                    if (dx != 0 || dy != 0) {
                      btProvider.sendMouseMove(
                        dx.round().clamp(-127, 127),
                        dy.round().clamp(-127, 127),
                      );
                    }
                  } else if (_pointerCount >= 2) {
                    // Two-finger scroll (we use dy for vertical scroll)
                    // Note: inverted sign often feels more natural depending on preferences,
                    // but we will send relative displacement.
                    final double scrollY = delta.dy * settings.scrollSensitivity;

                    if (scrollY != 0) {
                      btProvider.sendMouseScroll(
                        scrollY.round().clamp(-127, 127),
                      );
                    }
                  }
                },
                onTap: () {
                  if (isConnected) {
                    _sendLeftClick(btProvider);
                  }
                },
                onLongPress: () {
                  if (isConnected) {
                    _sendRightClick(btProvider);
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderCol, width: 1.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mouse,
                          size: 64,
                          color: isConnected ? AppTheme.accentBlue : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isConnected ? 'TOUCHPAD ZONE' : 'HOST DISCONNECTED',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.white : AppTheme.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected
                              ? '1 Finger: Move Cursor  •  Tap: Left Click\n2 Fingers: Scroll  •  Long Press: Right Click'
                              : 'Connect a paired device to activate touchpad.',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Buttons (Left Click / Right Click)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 68,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardBg,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderCol, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isConnected ? () => _sendLeftClick(btProvider) : null,
                      child: const Text(
                        'LEFT CLICK',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 68,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardBg,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderCol, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isConnected ? () => _sendRightClick(btProvider) : null,
                      child: const Text(
                        'RIGHT CLICK',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
