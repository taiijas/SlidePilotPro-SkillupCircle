import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class BluetoothService {
  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);

  // Callbacks from native code
  Function(bool enabled)? onBluetoothStateChanged;
  Function(bool supported)? onHidSupportStatusChanged;
  Function(String? address, int state)? onConnectionStateChanged;
  Function(bool registered)? onAppRegistrationStateChanged;

  BluetoothService() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onBluetoothStateChanged':
        onBluetoothStateChanged?.call(call.arguments as bool);
        break;
      case 'onHidSupportStatusChanged':
        onHidSupportStatusChanged?.call(call.arguments as bool);
        break;
      case 'onConnectionStateChanged':
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        onConnectionStateChanged?.call(args['address'] as String?, args['state'] as int);
        break;
      case 'onAppRegistrationStateChanged':
        onAppRegistrationStateChanged?.call(call.arguments as bool);
        break;
    }
  }

  Future<bool> checkHidSupport() async {
    try {
      return await _channel.invokeMethod<bool>('checkHidSupport') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> openBluetoothSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openBluetoothSettings') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermissions') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSystemInfo');
      if (info == null) return {};
      return Map<String, dynamic>.from(info);
    } on PlatformException catch (_) {
      return {};
    }
  }

  Future<bool> registerApp() async {
    try {
      return await _channel.invokeMethod<bool>('registerApp') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> initializeHidProfile() async {
    try {
      return await _channel.invokeMethod<bool>('initializeHidProfile') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<Map<String, String>>> getPairedDevices() async {
    try {
      final List<dynamic>? devices = await _channel.invokeMethod<List<dynamic>>('getPairedDevices');
      if (devices == null) return [];
      return devices.map((d) => Map<String, String>.from(d as Map)).toList();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> connectDevice(String address) async {
    try {
      return await _channel.invokeMethod<bool>('connectDevice', {'address': address}) ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> disconnectDevice() async {
    try {
      return await _channel.invokeMethod<bool>('disconnectDevice') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> sendKeyboardKey(String modifier, String key) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendKeyboardKey',
        {'modifier': modifier, 'key': key},
      );
      if (result == null) return {'success': false, 'error': 'No response from platform'};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'PlatformException'};
    }
  }

  Future<Map<String, dynamic>> sendKeyboardShortcut(String modifier, String key) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendKeyboardShortcut',
        {'modifier': modifier, 'key': key},
      );
      if (result == null) return {'success': false, 'error': 'No response from platform'};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'PlatformException'};
    }
  }

  Future<Map<String, dynamic>> sendMouseMove(int x, int y) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendMouseMove',
        {'x': x, 'y': y},
      );
      if (result == null) return {'success': false, 'error': 'No response from platform'};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'PlatformException'};
    }
  }

  Future<Map<String, dynamic>> sendMouseButton(int button, bool isPressed) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendMouseButton',
        {'button': button, 'isPressed': isPressed},
      );
      if (result == null) return {'success': false, 'error': 'No response from platform'};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'PlatformException'};
    }
  }

  Future<Map<String, dynamic>> sendMouseScroll(int scroll) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendMouseScroll',
        {'scroll': scroll},
      );
      if (result == null) return {'success': false, 'error': 'No response from platform'};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'PlatformException'};
    }
  }
}
