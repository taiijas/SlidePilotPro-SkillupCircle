import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ReceiverService with ChangeNotifier {
  WebSocket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _pairingStatus = 'Unpaired'; // 'Unpaired', 'Pairing', 'Paired', 'Failed'
  
  String? _host;
  int? _port;
  String? _pin;
  String? _deviceName;
  
  String? _lastCommandSent;
  int? _lastPingMs;
  DateTime? _pingStartTime;
  Timer? _pairingTimeoutTimer;
  
  List<Map<String, dynamic>> _savedReceivers = [];
  final List<String> _logs = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get pairingStatus => _pairingStatus;
  String? get host => _host;
  int? get port => _port;
  String? get pin => _pin;
  String? get deviceName => _deviceName;
  String? get lastCommandSent => _lastCommandSent;
  int? get lastPingMs => _lastPingMs;
  List<Map<String, dynamic>> get savedReceivers => _savedReceivers;
  List<String> get logs => _logs;

  ReceiverService() {
    _init();
  }

  void _log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final logMsg = '[$time] $message';
    debugPrint(logMsg);
    _logs.add(logMsg);
    // Keep logs list under 200 items to avoid bloated state
    if (_logs.length > 200) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _log('Logs cleared.');
  }

  Future<void> _init() async {
    _log('Initializing ReceiverService...');
    await loadSavedReceivers();
    
    // Load last receiver configs
    final prefs = await SharedPreferences.getInstance();
    final lastHost = prefs.getString(AppConstants.keyLastReceiverHost);
    final lastPort = prefs.getInt(AppConstants.keyLastReceiverPort);
    final lastPin = prefs.getString(AppConstants.keyLastReceiverPin);
    final autoReconnect = prefs.getBool(AppConstants.keyAutoReconnect) ?? true;

    if (autoReconnect && lastHost != null && lastPort != null && lastPin != null) {
      _log('Auto-reconnect enabled. Attempting reconnection to last receiver: $lastHost:$lastPort');
      // Attempt connection in background
      connectToReceiver(lastHost, lastPort, lastPin, 'Android Phone');
    }
  }

  Future<void> loadSavedReceivers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.keySavedReceivers);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _savedReceivers = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        _savedReceivers = [];
      }
      notifyListeners();
    } catch (e) {
      _log('Failed to load saved receivers: $e');
    }
  }

  Future<void> _saveReceiverProfile(String host, int port, String pin, String deviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if profile already exists, if so, update it, otherwise add new one
      final index = _savedReceivers.indexWhere((element) => element['host'] == host && element['port'] == port);
      final profile = {
        'host': host,
        'port': port,
        'pin': pin,
        'deviceName': deviceName,
        'lastConnected': DateTime.now().toIso8601String(),
      };
      
      if (index >= 0) {
        _savedReceivers[index] = profile;
      } else {
        _savedReceivers.add(profile);
      }
      
      await prefs.setString(AppConstants.keySavedReceivers, jsonEncode(_savedReceivers));
      _log('Saved receiver profile: $deviceName ($host:$port)');
      notifyListeners();
    } catch (e) {
      _log('Failed to save receiver profile: $e');
    }
  }

  Future<void> deleteSavedReceiver(String host, int port) async {
    try {
      _savedReceivers.removeWhere((element) => element['host'] == host && element['port'] == port);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySavedReceivers, jsonEncode(_savedReceivers));
      _log('Deleted saved receiver: $host:$port');
      notifyListeners();
    } catch (e) {
      _log('Failed to delete receiver profile: $e');
    }
  }

  Future<void> _saveLastReceiverConfig(String host, int port, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastReceiverHost, host);
    await prefs.setInt(AppConstants.keyLastReceiverPort, port);
    await prefs.setString(AppConstants.keyLastReceiverPin, pin);
  }

  Future<void> forgetLastReceiver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLastReceiverHost);
    await prefs.remove(AppConstants.keyLastReceiverPort);
    await prefs.remove(AppConstants.keyLastReceiverPin);
    _log('Forgot last receiver configuration.');
  }

  Future<bool> connectToReceiver(String host, int port, String pin, String deviceName) async {
    if (_isConnected || _isConnecting) {
      _log('Already connected or connecting. Disconnect first.');
      return false;
    }

    _log('Connecting to ws://$host:$port/ ...');
    _isConnecting = true;
    _pairingStatus = 'Pairing';
    _host = host;
    _port = port;
    _pin = pin;
    _deviceName = deviceName;
    notifyListeners();

    try {
      final wsUrl = Uri.parse('ws://$host:$port/');
      // Establish WebSocket connection with connection timeout
      const timeoutMs = 5000; // 5s timeout for initial TCP connection
      _socket = await WebSocket.connect(wsUrl.toString()).timeout(const Duration(milliseconds: timeoutMs));
      
      _isConnected = true;
      _isConnecting = false;
      _log('WebSocket connection established. Starting pairing challenge...');
      
      // Start listening to socket messages
      _socket!.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _log('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          _log('WebSocket connection closed by receiver');
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      // Start 10-second pairing challenge timeout
      _pairingTimeoutTimer?.cancel();
      _pairingTimeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_pairingStatus == 'Pairing') {
          _log('Pairing timeout (10 seconds exceeded)');
          _pairingStatus = 'Failed';
          disconnectReceiver();
        }
      });

      // Send pairing handshake packet immediately
      await _sendJson({
        "type": "system",
        "action": "pair",
        "pin": pin,
        "deviceName": deviceName
      });

      return true;
    } catch (e) {
      _log('Connection failed: $e');
      _handleDisconnect();
      return false;
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    if (_pairingStatus == 'Pairing') {
      _pairingStatus = 'Failed';
    }
    _pairingTimeoutTimer?.cancel();
    _socket = null;
    notifyListeners();
  }

  Future<void> disconnectReceiver() async {
    _log('Disconnect requested...');
    _pairingTimeoutTimer?.cancel();
    if (_socket != null) {
      try {
        await _socket!.close(WebSocketStatus.normalClosure, 'Client disconnecting');
      } catch (e) {
        _log('Error during close: $e');
      }
    }
    _handleDisconnect();
  }

  void _handleMessage(dynamic data) {
    try {
      final map = jsonDecode(data as String) as Map<String, dynamic>;
      final ok = map['ok'] == true;
      
      if (_pairingStatus == 'Pairing') {
        _pairingTimeoutTimer?.cancel();
        if (ok) {
          _pairingStatus = 'Paired';
          _log('Pairing succeeded!');
          _saveReceiverProfile(_host!, _port!, _pin!, _deviceName ?? 'Windows Receiver');
          _saveLastReceiverConfig(_host!, _port!, _pin!);
        } else {
          _pairingStatus = 'Failed';
          _log('Pairing failed: ${map['error'] ?? 'invalid pin'}');
          disconnectReceiver();
        }
        notifyListeners();
      } else {
        // Handle command responses or ping responses
        if (_pingStartTime != null) {
          _lastPingMs = DateTime.now().difference(_pingStartTime!).inMilliseconds;
          _pingStartTime = null;
          _log('Ping response: ${_lastPingMs}ms');
          notifyListeners();
        }
      }
    } catch (e) {
      _log('Failed to parse incoming WebSocket message: $e');
    }
  }

  Future<void> _sendJson(Map<String, dynamic> jsonMap) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      _log('Error: Socket not open, cannot send packet.');
      return;
    }
    
    try {
      final rawJson = jsonEncode(jsonMap);
      _socket!.add(rawJson);
      if (jsonMap['action'] != 'move') { // Do not pollute logs with mouse move events
        _lastCommandSent = rawJson;
        _log('Sent command: $rawJson');
      }
    } catch (e) {
      _log('Error sending command: $e');
    }
  }

  Future<void> sendKeyboardKey(String key) async {
    await _sendJson({
      "type": "keyboard",
      "action": "key",
      "key": key
    });
  }

  Future<void> sendKeyboardShortcut(List<String> keys) async {
    await _sendJson({
      "type": "keyboard",
      "action": "shortcut",
      "keys": keys
    });
  }

  Future<void> sendMouseMove(int dx, int dy) async {
    await _sendJson({
      "type": "mouse",
      "action": "move",
      "dx": dx,
      "dy": dy
    });
  }

  Future<void> sendMouseClick(String button) async {
    await _sendJson({
      "type": "mouse",
      "action": "click",
      "button": button
    });
  }

  Future<void> sendMouseButtonDown(String button) async {
    await _sendJson({
      "type": "mouse",
      "action": "button_down",
      "button": button
    });
  }

  Future<void> sendMouseButtonUp(String button) async {
    await _sendJson({
      "type": "mouse",
      "action": "button_up",
      "button": button
    });
  }

  Future<void> sendMouseScroll(int delta) async {
    await _sendJson({
      "type": "mouse",
      "action": "scroll",
      "delta": delta
    });
  }

  Future<void> sendGesture(String action, String profile) async {
    await _sendJson({
      "type": "gesture",
      "action": action,
      "profile": profile
    });
  }

  Future<void> ping() async {
    if (!_isConnected || _socket == null) return;
    _pingStartTime = DateTime.now();
    await _sendJson({
      "type": "system",
      "action": "ping"
    });
  }
}
