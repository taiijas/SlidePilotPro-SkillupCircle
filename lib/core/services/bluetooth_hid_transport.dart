import '../../features/bluetooth/providers/bluetooth_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import 'control_transport.dart';

class BluetoothHidTransport implements ControlTransport {
  final BluetoothProvider bluetoothProvider;
  final SettingsProvider settingsProvider;

  BluetoothHidTransport({
    required this.bluetoothProvider,
    required this.settingsProvider,
  });

  @override
  Future<void> sendKeyboardKey(String modifier, String key) async {
    await bluetoothProvider.sendKeyboardKey(modifier, key);
  }

  @override
  Future<void> sendKeyboardShortcut(String modifier, String key) async {
    await bluetoothProvider.sendKeyboardShortcut(modifier, key);
  }

  @override
  Future<void> sendMouseMove(int dx, int dy) async {
    await bluetoothProvider.sendMouseMove(dx, dy);
  }

  @override
  Future<void> sendMouseButton(int button, bool isPressed) async {
    await bluetoothProvider.sendMouseButton(button, isPressed);
  }

  @override
  Future<void> sendLeftClick() async {
    await bluetoothProvider.sendLeftClick();
  }

  @override
  Future<void> sendMouseScroll(int delta) async {
    await bluetoothProvider.sendMouseScroll(delta);
  }

  @override
  Future<void> sendGesture(String action, String profile) async {
    // Determine type and direction of swipe from action:
    // e.g. "three_finger_swipe_up"
    final parts = action.split('_');
    if (parts.length < 4) return;
    
    final fingerCount = parts[0]; // "three" or "four"
    final direction = parts[3]; // "up", "down", "left", "right"
    
    if (fingerCount == 'three') {
      if (profile == 'macos') {
        switch (direction) {
          case 'up':
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "up_arrow");
            break;
          case 'down':
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "down_arrow");
            break;
          case 'left':
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "left_arrow");
            break;
          case 'right':
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "right_arrow");
            break;
        }
      } else if (profile == 'windows') {
        switch (direction) {
          case 'up':
            await bluetoothProvider.sendKeyboardShortcut("meta", "tab"); // Task View
            break;
          case 'down':
            await bluetoothProvider.sendKeyboardShortcut("meta", "d"); // Show Desktop
            break;
          case 'left':
            await bluetoothProvider.sendKeyboardShortcut("alt", "tab"); // Switch app
            break;
          case 'right':
            await bluetoothProvider.sendKeyboardShortcut("alt+shift", "tab"); // Switch app reverse
            break;
        }
      } else if (profile == 'linux') {
        switch (direction) {
          case 'up':
            await bluetoothProvider.sendKeyboardShortcut("meta", "tab");
            break;
          case 'down':
            await bluetoothProvider.sendKeyboardShortcut("meta", "d");
            break;
          case 'left':
            await bluetoothProvider.sendKeyboardShortcut("alt", "tab");
            break;
          case 'right':
            await bluetoothProvider.sendKeyboardShortcut("alt+shift", "tab");
            break;
        }
      } else {
        // Fallback
        switch (direction) {
          case 'left':
            await bluetoothProvider.sendKeyboardShortcut("", "left_arrow");
            break;
          case 'right':
            await bluetoothProvider.sendKeyboardShortcut("", "right_arrow");
            break;
          case 'up':
            await bluetoothProvider.sendKeyboardShortcut("", "up_arrow");
            break;
          case 'down':
            await bluetoothProvider.sendKeyboardShortcut("", "down_arrow");
            break;
        }
      }
    } else if (fingerCount == 'four') {
      if (profile == 'macos') {
        if (direction == 'left') {
          if (settingsProvider.macosFourFingerSwipeOption == 'app_switching') {
            await bluetoothProvider.sendKeyboardShortcut("meta", "tab");
          } else {
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "left_arrow");
          }
        } else if (direction == 'right') {
          if (settingsProvider.macosFourFingerSwipeOption == 'app_switching') {
            await bluetoothProvider.sendKeyboardShortcut("meta+shift", "tab");
          } else {
            await bluetoothProvider.sendKeyboardShortcut("ctrl", "right_arrow");
          }
        }
      } else if (profile == 'windows') {
        if (direction == 'left') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl+meta", "left_arrow"); // Virtual Desktop Left
        } else if (direction == 'right') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl+meta", "right_arrow"); // Virtual Desktop Right
        }
      } else if (profile == 'linux') {
        if (direction == 'left') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl+alt", "left_arrow");
        } else if (direction == 'right') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl+alt", "right_arrow");
        }
      } else {
        // Fallback
        if (direction == 'left') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl", "left_arrow");
        } else if (direction == 'right') {
          await bluetoothProvider.sendKeyboardShortcut("ctrl", "right_arrow");
        }
      }
    }
  }

  @override
  bool get isConnected => bluetoothProvider.hostConnectionState == 2;

  @override
  String get connectionStatusName {
    if (!bluetoothProvider.isHidSupported) {
      return 'HID Unsupported';
    }
    switch (bluetoothProvider.hostConnectionState) {
      case 2:
        return 'Bluetooth HID Connected';
      case 1:
        return 'Connecting';
      default:
        return 'Disconnected';
    }
  }
}
