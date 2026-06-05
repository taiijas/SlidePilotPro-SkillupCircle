import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../bluetooth/providers/bluetooth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../services/gesture_engine.dart';

class TrackpadScreen extends StatefulWidget {
  const TrackpadScreen({super.key});

  @override
  State<TrackpadScreen> createState() => _TrackpadScreenState();
}

class _TrackpadScreenState extends State<TrackpadScreen> {
  late GestureEngine _gestureEngine;
  String _activeGesture = "";
  String? _warningMessage;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    _gestureEngine = GestureEngine(
      onGestureChange: (gestureName) {
        setState(() {
          _activeGesture = gestureName;
        });
      },
      onConnectionWarning: (warning) {
        setState(() {
          _warningMessage = warning;
        });
        _warningTimer?.cancel();
        _warningTimer = Timer(const Duration(seconds: 3), () {
          setState(() {
            _warningMessage = null;
          });
        });
      },
    );
  }

  @override
  void dispose() {
    _warningTimer?.cancel();
    super.dispose();
  }

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

  void _runDiagnosticShortcut(BluetoothProvider btProvider, String modifier, String key) async {
    _triggerHaptic(context);
    final connected = btProvider.hostConnectionState == 2;
    if (!connected) {
      setState(() {
        _warningMessage = "Cannot send diagnostic: Host disconnected.";
      });
      _warningTimer?.cancel();
      _warningTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _warningMessage = null;
        });
      });
      return;
    }
    
    await btProvider.sendKeyboardShortcut(modifier, key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent shortcut: $modifier + $key'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = Provider.of<BluetoothProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isConnected = btProvider.hostConnectionState == 2;

    final isTrackpadMode = settings.gestureMode == 'trackpad';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTrackpadMode ? 'Wireless Trackpad' : 'Presentation Controller'),
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
              backgroundColor: isConnected 
                  ? AppTheme.success.withValues(alpha: 0.2) 
                  : AppTheme.error.withValues(alpha: 0.2),
              side: BorderSide(color: isConnected ? AppTheme.success : AppTheme.error),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Warning Banner
            if (_warningMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  border: Border.all(color: AppTheme.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _warningMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Mode & Active Gesture Display Bar
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderCol),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESPONSE MODE',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTrackpadMode ? 'Trackpad Gesture Mode' : 'Presentation Gesture Mode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                  if (_activeGesture.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentBlue),
                      ),
                      child: Text(
                        _activeGesture,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    const Text(
                      'Ready',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),

            // Trackpad Canvas Area
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _gestureEngine.handlePointerEvent(e, btProvider, settings),
                onPointerMove: (e) => _gestureEngine.handlePointerEvent(e, btProvider, settings),
                onPointerUp: (e) => _gestureEngine.handlePointerEvent(e, btProvider, settings),
                onPointerCancel: (e) => _gestureEngine.handlePointerEvent(e, btProvider, settings),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isConnected ? AppTheme.accentBlue.withValues(alpha: 0.5) : AppTheme.borderCol, width: 2),
                    boxShadow: isConnected ? [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ] : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTrackpadMode ? Icons.mouse : Icons.play_circle_outline,
                          size: 72,
                          color: isConnected ? AppTheme.accentBlue : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isConnected 
                              ? (isTrackpadMode ? 'TOUCHPAD ZONE' : 'PRESENTATION ZONE')
                              : 'HOST DISCONNECTED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.white : AppTheme.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected
                              ? (isTrackpadMode 
                                  ? 'Move cursor, scroll, pinch to zoom, and swipe.'
                                  : 'Swipe left/right to navigate. Tap to trigger screen states.')
                              : 'Connect a paired host device in Settings to control.',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Gesture Reference Guide Card (if enabled in settings)
            if (settings.showGestureGuide)
              _buildGestureGuideCard(context, settings),

            // Mouse Buttons Row (Always shown in trackpad mode, or presentation mode if desired)
            if (isTrackpadMode) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBg,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderCol, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isConnected ? () => _sendLeftClick(btProvider) : null,
                        child: const Text(
                          'LEFT CLICK',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBg,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderCol, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isConnected ? () => _sendRightClick(btProvider) : null,
                        child: const Text(
                          'RIGHT CLICK',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Diagnostics Panel
            _buildDiagnosticsPanel(context, btProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureGuideCard(BuildContext context, SettingsProvider settings) {
    final mode = settings.gestureMode;
    final profile = settings.platformProfile;
    
    String guideTitle = "Mac Touchpad Shortcuts";
    List<String> items = [];

    if (mode == 'presentation') {
      guideTitle = "Presentation Gestures";
      items = [
        "Swipe Left/Right: Next/Prev Slide",
        "Double Tap: Start Slideshow",
        "Long Press: Exit Slideshow (Esc)",
        "2-Finger Tap: Black Screen (b)",
        "3-Finger Tap: White Screen (w)",
      ];
    } else {
      if (profile == 'macos') {
        guideTitle = "macOS Gesture Shortcuts";
        items = [
          "1 Finger Drag: Move Cursor",
          "1 Finger Tap: Left Click",
          "2 Finger Tap: Right Click",
          "2 Finger Vertical Drag: Scroll",
          "Pinch Out / In: Zoom In / Out",
          "3 Finger Swipe Up / Down: Mission Control / Exposé",
          "3 Finger Swipe Left / Right: Change space/desktop",
          settings.macosFourFingerSwipeOption == 'app_switching' 
              ? "4 Finger Swipe Left / Right: App Switcher (Cmd+Tab)" 
              : "4 Finger Swipe Left / Right: Space switching",
        ];
      } else if (profile == 'windows') {
        guideTitle = "Windows Gesture Shortcuts";
        items = [
          "1 Finger Drag: Move Cursor",
          "1 Finger Tap: Left Click",
          "2 Finger Tap: Right Click",
          "2 Finger Vertical Drag: Scroll",
          "Pinch Out / In: Zoom In / Out",
          "3 Finger Swipe Up / Down: Task View / Show Desktop",
          "3 Finger Swipe Left / Right: Switch Apps (Alt+Tab)",
          "4 Finger Swipe Left / Right: Virtual Desktop Switch",
        ];
      } else if (profile == 'linux') {
        guideTitle = "Linux Gesture Shortcuts";
        items = [
          "1 Finger Drag: Move Cursor",
          "1 Finger Tap: Left Click",
          "2 Finger Tap: Right Click",
          "2 Finger Vertical Drag: Scroll",
          "Pinch Out / In: Zoom In / Out",
          "3 Finger Swipe Up / Down: Workspace Overview",
          "3 Finger Swipe Left / Right: Switch Apps (Alt+Tab)",
          "4 Finger Swipe Left / Right: Workspace Switch",
        ];
      } else {
        guideTitle = "${profile.toUpperCase()} Shortcuts";
        items = [
          "1 Finger Drag: Move Cursor  •  1 Finger Tap: Left Click",
          "2 Finger Tap: Right Click  •  2 Finger Scroll: Scroll",
          "Pinch In/Out: Zoom Out/In",
          "3 Finger Swipe: Workspace Actions",
        ];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.6),
        border: Border.all(color: AppTheme.borderCol, width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(Icons.help_outline, color: AppTheme.accentBlue, size: 20),
        title: Text(
          guideTitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(color: AppTheme.accentBlue, fontSize: 11)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.2),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDiagnosticsPanel(BuildContext context, BluetoothProvider btProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 16, color: AppTheme.textMuted),
              SizedBox(width: 8),
              Text(
                'HID DIANOSTICS PANEL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDiagButton(btProvider, 'Cmd + Plus', 'meta', 'plus'),
                _buildDiagButton(btProvider, 'Cmd - Minus', 'meta', 'minus'),
                _buildDiagButton(btProvider, 'Ctrl + Up', 'ctrl', 'up_arrow'),
                _buildDiagButton(btProvider, 'Ctrl + Left', 'ctrl', 'left_arrow'),
                _buildDiagButton(btProvider, 'Alt + Tab', 'alt', 'tab'),
                _buildDiagButton(btProvider, 'Win + Tab', 'meta', 'tab'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDiagButton(BluetoothProvider btProvider, String label, String mod, String key) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.borderCol.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderCol),
          ),
        ),
        onPressed: () => _runDiagnosticShortcut(btProvider, mod, key),
        child: Text(label),
      ),
    );
  }
}
