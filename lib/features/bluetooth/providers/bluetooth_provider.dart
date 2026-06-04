import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier, WidgetsBindingObserver {
  final BluetoothService _bluetoothService = BluetoothService();
  
  // State variables
  bool _isBluetoothEnabled = false;
  bool _isHidSupported = false; // Maps to: HID Profile Available
  bool _isAppRegistered = false; // Maps to: HID App Registered
  int _connectionState = 0; // 0: Disconnected, 1: Connecting, 2: Connected, 3: Disconnecting
  bool _hasPermissions = false;
  
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;
  
  String? _lastDeviceAddress;
  String? _lastDeviceName;

  List<Map<String, String>> _pairedDevices = [];
  bool _isLoadingDevices = false;

  // Logging & Diagnostics
  final List<String> _logs = [];
  Map<String, dynamic> _diagnosticsResult = {};

  // Getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isHidSupported => _isHidSupported;
  bool get isAppRegistered => _isAppRegistered;
  int get connectionState => _connectionState;
  int get hostConnectionState => _connectionState;
  bool get hasPermissionsState => _hasPermissions;
  
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDevice => _connectedDeviceName;

  // Throttling mouse move logs
  int _pendingMouseMoveCount = 0;
  DateTime? _lastMouseMoveLogTime;
  bool _isMouseMoveLogTimerActive = false;
  
  String? get lastDeviceAddress => _lastDeviceAddress;
  String? get lastDeviceName => _lastDeviceName;
  
  List<Map<String, String>> get pairedDevices => _pairedDevices;
  bool get isLoadingDevices => _isLoadingDevices;

  List<String> get logs => _logs;
  Map<String, dynamic> get diagnosticsResult => _diagnosticsResult;

  BluetoothProvider() {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final logMsg = '[$time] $message';
    debugPrint(logMsg);
    _logs.add(logMsg);
    notifyListeners();
  }

  void _init() {
    log('Initializing BluetoothProvider...');
    
    // Set native callback listeners
    _bluetoothService.onBluetoothStateChanged = (enabled) {
      log('Native callback: Bluetooth enabled status changed: $enabled');
      _isBluetoothEnabled = enabled;
      notifyListeners();
      if (enabled) {
        refreshDevices();
      }
    };

    _bluetoothService.onHidSupportStatusChanged = (supported) {
      log('Native callback: HID Profile Proxy availability changed: $supported');
      _isHidSupported = supported;
      notifyListeners();
    };

    _bluetoothService.onAppRegistrationStateChanged = (registered) {
      log('Native callback: HID App registration status changed: $registered');
      _isAppRegistered = registered;
      notifyListeners();
    };

    _bluetoothService.onConnectionStateChanged = (address, state) {
      final stateNames = {0: 'Disconnected', 1: 'Connecting', 2: 'Connected', 3: 'Disconnecting'};
      log('Native callback: Host connection state changed to: ${stateNames[state] ?? state} for device: $address');
      
      _connectionState = state;
      if (state == 2) { // Connected
        _connectedDeviceAddress = address;
        final device = _pairedDevices.firstWhere(
          (d) => d['address'] == address,
          orElse: () => {'name': 'Unknown Host', 'address': address ?? ''},
        );
        _connectedDeviceName = device['name'];
        _saveLastDevice(_connectedDeviceName!, _connectedDeviceAddress!);
      } else if (state == 0) { // Disconnected
        _connectedDeviceAddress = null;
        _connectedDeviceName = null;
      }
      notifyListeners();
    };

    _checkInitialPermissionsAndLoad();
  }

  Future<void> _checkInitialPermissionsAndLoad() async {
    _hasPermissions = await _bluetoothService.checkPermissions();
    log('Initial permissions check: $_hasPermissions');
    
    if (_hasPermissions) {
      await _loadInitialStates();
    } else {
      log('Permissions are missing. Please request permissions using the "Grant Permissions" flow.');
    }
  }

  Future<void> _loadInitialStates() async {
    log('Loading initial Bluetooth and HID states...');
    _isBluetoothEnabled = await _bluetoothService.isBluetoothEnabled();
    log('Bluetooth Adapter isEnabled: $_isBluetoothEnabled');

    // Trigger SDK Profile initialization
    await _bluetoothService.initializeHidProfile();
    _isHidSupported = await _bluetoothService.checkHidSupport();
    log('HID Profile supported on hardware: $_isHidSupported');

    final prefs = await SharedPreferences.getInstance();
    _lastDeviceAddress = prefs.getString(AppConstants.keyLastDeviceAddress);
    _lastDeviceName = prefs.getString(AppConstants.keyLastDeviceName);
    if (_lastDeviceAddress != null) {
      log('Retrieved last connected device: $_lastDeviceName ($_lastDeviceAddress)');
    }

    await refreshDevices();

    // Trigger auto-reconnect if last device exists and is enabled
    final autoReconnect = prefs.getBool(AppConstants.keyAutoReconnect) ?? true;
    if (autoReconnect && _lastDeviceAddress != null && _isBluetoothEnabled) {
      log('Auto-reconnect is enabled, attempting connection to last host: $_lastDeviceAddress');
      connectDevice(_lastDeviceAddress!);
    }
  }

  Future<bool> requestPermissions() async {
    log('Requesting runtime Bluetooth permissions...');
    final granted = await _bluetoothService.requestPermissions();
    log('Permissions request result: $granted');
    _hasPermissions = granted;
    notifyListeners();

    if (granted) {
      await _loadInitialStates();
    }
    return granted;
  }

  Future<void> refreshDevices() async {
    if (!_hasPermissions) {
      log('Cannot scan: Permissions not granted.');
      return;
    }
    if (!_isBluetoothEnabled) {
      log('Cannot fetch paired devices: Bluetooth is disabled.');
      return;
    }
    
    _isLoadingDevices = true;
    notifyListeners();

    log('Fetching paired/bonded devices from Android adapter...');
    _pairedDevices = await _bluetoothService.getPairedDevices();
    log('Found ${_pairedDevices.length} paired devices.');

    _isLoadingDevices = false;
    notifyListeners();
  }

  Future<bool> registerApp() async {
    log('Initiating HID app registration...');
    if (!_isHidSupported) {
      log('Error: HID Profile is not available. Cannot register app.');
      return false;
    }
    final success = await _bluetoothService.registerApp();
    log('Register app call success: $success');
    return success;
  }

  Future<bool> connectDevice(String address) async {
    log('Connect requested for device address: $address');
    
    if (!_isHidSupported) {
      log('Error: Cannot connect. HID profile is unavailable.');
      return false;
    }

    if (!_isAppRegistered) {
      log('HID app is not registered. Registering before connecting...');
      final registered = await registerApp();
      if (!registered) {
        log('Error: Failed to register HID app. Aborting connection.');
        return false;
      }
      // Wait slightly for app registration to register inside Bluetooth system
      await Future.delayed(const Duration(milliseconds: 500));
    }

    log('Calling bluetoothHidDevice.connect($address)...');
    _connectionState = 1; // Connecting
    notifyListeners();
    
    final success = await _bluetoothService.connectDevice(address);
    if (!success) {
      log('Error: connectDevice call failed.');
      _connectionState = 0; // Disconnected
      notifyListeners();
    } else {
      log('Connect call acknowledged by host.');
    }
    return success;
  }

  Future<bool> disconnectDevice() async {
    log('Disconnect requested...');
    _connectionState = 3; // Disconnecting
    notifyListeners();
    
    final success = await _bluetoothService.disconnectDevice();
    if (!success) {
      log('Error: disconnectDevice call failed.');
      _connectionState = 2; // Restore to connected
      notifyListeners();
    } else {
      log('Disconnect call acknowledged.');
    }
    return success;
  }

  Future<void> _saveLastDevice(String name, String address) async {
    _lastDeviceName = name;
    _lastDeviceAddress = address;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastDeviceAddress, address);
    await prefs.setString(AppConstants.keyLastDeviceName, name);
    notifyListeners();
  }

  Future<void> forgetLastDevice() async {
    log('Forgetting saved device data...');
    _lastDeviceName = null;
    _lastDeviceAddress = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLastDeviceAddress);
    await prefs.remove(AppConstants.keyLastDeviceName);
    notifyListeners();
  }

  Future<void> runDiagnostics() async {
    log('Running system diagnostics...');
    final Map<String, dynamic> result = {};

    try {
      final info = await _bluetoothService.getSystemInfo();
      result['android_version'] = info['release'] ?? 'Unknown';
      result['api_level'] = info['sdk'] ?? 0;
      result['device_model'] = info['model'] ?? 'Unknown';
      result['manufacturer'] = info['manufacturer'] ?? 'Unknown';
    } catch (e) {
      result['android_version'] = 'Unknown';
      result['api_level'] = 0;
      result['device_model'] = 'Android Device';
      result['manufacturer'] = 'Generic';
    }

    result['bluetooth_permissions'] = _hasPermissions;
    result['bluetooth_enabled'] = _isBluetoothEnabled;
    result['hid_profile_available'] = _isHidSupported;
    result['hid_app_registered'] = _isAppRegistered;
    result['paired_devices_count'] = _pairedDevices.length;
    result['host_connected'] = (_connectionState == 2);

    _diagnosticsResult = result;
    log('Diagnostics completed successfully.');
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    log('Logs cleared.');
  }

  Future<bool> openBluetoothSettings() {
    log('Requesting to open native Bluetooth settings...');
    return _bluetoothService.openBluetoothSettings();
  }

  // Keyboard controls
  Future<Map<String, dynamic>> sendKeyboardKey(String modifier, String key) async {
    log('Sending HID keyboard press: modifier=$modifier, key=$key');
    final result = await _bluetoothService.sendKeyboardKey(modifier, key);
    _logHidReport(result, 'Keyboard');
    return result;
  }

  // Mouse controls
  Future<Map<String, dynamic>> sendMouseMove(int x, int y) async {
    final result = await _bluetoothService.sendMouseMove(x, y);
    _logHidReport(result, 'Mouse Move');
    return result;
  }

  Future<Map<String, dynamic>> sendMouseButton(int button, bool isPressed) async {
    log('Sending HID mouse click: button=$button, isPressed=$isPressed');
    final result = await _bluetoothService.sendMouseButton(button, isPressed);
    _logHidReport(result, 'Mouse Button');
    return result;
  }

  Future<Map<String, dynamic>> sendMouseScroll(int scroll) async {
    final result = await _bluetoothService.sendMouseScroll(scroll);
    _logHidReport(result, 'Mouse Scroll');
    return result;
  }

  Future<Map<String, dynamic>> sendLeftClick() async {
    log('Sending HID Left Click macro');
    final pressResult = await sendMouseButton(0, true);
    await Future.delayed(const Duration(milliseconds: 30));
    final releaseResult = await sendMouseButton(0, false);
    return {
      'success': (pressResult['success'] == true) && (releaseResult['success'] == true),
      'reportType': 'macro',
      'reportId': 0,
      'bytes': '${pressResult['bytes']} -> ${releaseResult['bytes']}',
      'action': 'Left Click Macro (Press & Release)',
    };
  }

  void _logHidReport(Map<String, dynamic> result, String source) {
    if (source == 'Mouse Move') {
      _logMouseMoveThrottle(result);
      return;
    }

    final success = result['success'] == true;
    final reportType = result['reportType'] ?? 'unknown';
    final reportId = result['reportId'] ?? 0;
    final bytes = result['bytes'] ?? '[]';
    final action = result['action'] ?? 'unknown';
    
    if (success) {
      log('HID SENT OK ($source) -> Type: $reportType, ID: $reportId, Bytes: $bytes, Action: $action');
    } else {
      final error = result['error'] ?? 'unknown error';
      log('HID SEND FAILED ($source) -> Type: $reportType, ID: $reportId, Action: $action, Error: $error');
    }
  }

  void _logMouseMoveThrottle(Map<String, dynamic> result) {
    _pendingMouseMoveCount++;
    final now = DateTime.now();
    
    // In debug mode, print full mouse move report immediately to standard output for development.
    final success = result['success'] == true;
    final bytes = result['bytes'] ?? '[]';
    final action = result['action'] ?? 'unknown';
    
    debugPrint('HID SENT MOUSE -> Result: $success, Bytes: $bytes, Action: $action');
    
    if (_lastMouseMoveLogTime == null || now.difference(_lastMouseMoveLogTime!) >= const Duration(milliseconds: 300)) {
      _flushMouseMoveLog(result);
    } else if (!_isMouseMoveLogTimerActive) {
      _isMouseMoveLogTimerActive = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        _isMouseMoveLogTimerActive = false;
        _flushMouseMoveLog(result);
      });
    }
  }

  void _flushMouseMoveLog(Map<String, dynamic> lastResult) {
    if (_pendingMouseMoveCount == 0) return;
    
    final success = lastResult['success'] == true;
    final reportType = lastResult['reportType'] ?? 'mouse';
    final reportId = lastResult['reportId'] ?? 2;
    final bytes = lastResult['bytes'] ?? '[]';
    final action = lastResult['action'] ?? 'unknown';
    
    if (success) {
      log('HID SENT OK (Mouse Move) -> Type: $reportType, ID: $reportId, Bytes: $bytes, Action: $action (x$_pendingMouseMoveCount reports)');
    } else {
      final error = lastResult['error'] ?? 'unknown error';
      log('HID SEND FAILED (Mouse Move) -> Type: $reportType, ID: $reportId, Action: $action, Error: $error (x$_pendingMouseMoveCount reports)');
    }
    
    _pendingMouseMoveCount = 0;
    _lastMouseMoveLogTime = DateTime.now();
  }

  // App Lifecycle Handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('App lifecycle state changed: $state');
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    } else if (state == AppLifecycleState.paused) {
      _handleAppPause();
    }
  }

  void _handleAppPause() {
    log('App paused, temporary background state. App registration state is: $_isAppRegistered');
  }

  Future<void> _handleAppResume() async {
    log('App resumed, running resume check...');
    // check permissions
    _hasPermissions = await _bluetoothService.checkPermissions();
    log('Resume check: permissions = $_hasPermissions');
    
    if (_hasPermissions) {
      // check Bluetooth enabled
      _isBluetoothEnabled = await _bluetoothService.isBluetoothEnabled();
      log('Resume check: Bluetooth enabled = $_isBluetoothEnabled');
      
      if (_isBluetoothEnabled) {
        // Re-initialize/verify HID profile proxy
        await _bluetoothService.initializeHidProfile();
        
        // Wait slightly for proxy connection to establish
        await Future.delayed(const Duration(milliseconds: 300));
        _isHidSupported = await _bluetoothService.checkHidSupport();
        log('Resume check: HID support = $_isHidSupported');
        
        if (_isHidSupported) {
          // register HID app again if not registered
          if (!_isAppRegistered) {
            log('Resume check: HID app not registered. Attempting re-registration...');
            await registerApp();
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        
        // refresh bonded devices
        await refreshDevices();
        
        // if autoReconnect enabled and last device exists:
        final prefs = await SharedPreferences.getInstance();
        final autoReconnect = prefs.getBool(AppConstants.keyAutoReconnect) ?? true;
        if (autoReconnect && _lastDeviceAddress != null) {
          if (_connectionState == 0) { // STATE_DISCONNECTED
            log('Resume check: Auto-reconnect enabled, attempting reconnection to last host: $_lastDeviceAddress');
            await connectDevice(_lastDeviceAddress!);
          }
        }
      }
    }
    notifyListeners();
  }
}
