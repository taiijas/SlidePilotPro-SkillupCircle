import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/transport_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PresenterScreen extends StatelessWidget {
  const PresenterScreen({super.key});

  void _sendAction(BuildContext context, String action) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final transportProvider = Provider.of<TransportProvider>(context, listen: false);

    if (!transportProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not connected: ${transportProvider.connectionStatusName}. Please connect in the Connect tab.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (settings.hapticFeedback) {
      HapticFeedback.vibrate();
    }

    String modifier = '';
    String key = '';

    switch (settings.presentationProfile) {
      case 'powerpoint_win':
        switch (action) {
          case 'next': key = 'right_arrow'; break;
          case 'prev': key = 'left_arrow'; break;
          case 'start': key = 'f5'; break;
          case 'exit': key = 'escape'; break;
          case 'black': key = 'b'; break;
          case 'white': key = 'w'; break;
        }
        break;
      case 'powerpoint_mac':
        switch (action) {
          case 'next': key = 'right_arrow'; break;
          case 'prev': key = 'left_arrow'; break;
          case 'start': key = 'f5'; break;
          case 'exit': key = 'escape'; break;
          case 'black': key = 'b'; break;
          case 'white': key = 'w'; break;
        }
        break;
      case 'google_slides':
        switch (action) {
          case 'next': key = 'right_arrow'; break;
          case 'prev': key = 'left_arrow'; break;
          case 'start': modifier = 'ctrl'; key = 'f5'; break; // Ctrl + F5
          case 'exit': key = 'escape'; break;
          case 'black': key = 'b'; break;
          case 'white': key = 'w'; break;
        }
        break;
      case 'keynote':
        switch (action) {
          case 'next': key = 'right_arrow'; break;
          case 'prev': key = 'left_arrow'; break;
          case 'start': modifier = 'cmd+alt'; key = 'p'; break; // Cmd + Opt + P
          case 'exit': key = 'escape'; break;
          case 'black': key = 'b'; break;
          case 'white': key = 'w'; break;
        }
        break;
      default:
        // Default standard mapping
        switch (action) {
          case 'next': key = 'right_arrow'; break;
          case 'prev': key = 'left_arrow'; break;
          case 'start': key = 'f5'; break;
          case 'exit': key = 'escape'; break;
          case 'black': key = 'b'; break;
          case 'white': key = 'w'; break;
        }
    }

    if (key.isNotEmpty) {
      transportProvider.activeTransport.sendKeyboardKey(modifier, key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transportProvider = Provider.of<TransportProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final status = transportProvider.connectionStatusName;
    final isConnected = transportProvider.isConnected;
    final isWaiting = status == 'Receiver Waiting' || status == 'Connecting';
    final chipColor = isConnected 
        ? AppTheme.success 
        : (isWaiting ? Colors.amber : AppTheme.error);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presenter Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              backgroundColor: chipColor.withValues(alpha: 0.2),
              side: BorderSide(color: chipColor),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Gesture Swipe Box
            Expanded(
              flex: 4,
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    // Swipe Left (Next Slide)
                    _sendAction(context, 'next');
                  } else if (details.primaryVelocity! > 0) {
                    // Swipe Right (Previous Slide)
                    _sendAction(context, 'prev');
                  }
                },
                onDoubleTap: () {
                  _sendAction(context, 'start');
                },
                onLongPress: () {
                  _sendAction(context, 'exit');
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderCol, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, size: 64, color: AppTheme.accentBlue),
                      SizedBox(height: 16),
                      Text(
                        'TOUCH & SWIPE ZONE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Swipe Left: Next Slide\nSwipe Right: Prev Slide\nDouble Tap: Start Show\nLong Press: Exit Show',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Buttons (Prev / Next)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBg,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderCol, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 28),
                        label: const Text('PREVIOUS'),
                        onPressed: () => _sendAction(context, 'prev'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 28),
                        label: const Text('NEXT'),
                        onPressed: () => _sendAction(context, 'next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controls buttons (Start / Exit / Black / White)
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildControlBtn(context, Icons.play_arrow, 'START', () => _sendAction(context, 'start')),
                  _buildControlBtn(context, Icons.stop, 'EXIT', () => _sendAction(context, 'exit')),
                  _buildControlBtn(context, Icons.brightness_1, 'BLACK SCREEN', () => _sendAction(context, 'black')),
                  _buildControlBtn(context, Icons.brightness_5, 'WHITE SCREEN', () => _sendAction(context, 'white')),
                ],
              ),
            ),

            // Profile info indicator
            Text(
              'Profile: ${AppConstants.presentationProfiles[settings.presentationProfile] ?? settings.presentationProfile}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardBg,
        foregroundColor: Colors.white70,
        side: const BorderSide(color: AppTheme.borderCol, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }
}
