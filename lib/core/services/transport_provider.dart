import 'package:flutter/material.dart';
import '../../features/bluetooth/providers/bluetooth_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import 'bluetooth_hid_transport.dart';
import 'control_transport.dart';
import 'receiver_websocket_transport.dart';
import 'receiver_service.dart';

class TransportProvider with ChangeNotifier {
  SettingsProvider settingsProvider;
  BluetoothProvider bluetoothProvider;
  ReceiverService receiverService;

  late BluetoothHidTransport _bluetoothHidTransport;
  late ReceiverWebSocketTransport _receiverWebSocketTransport;

  TransportProvider(
    this.settingsProvider,
    this.bluetoothProvider,
    this.receiverService,
  ) {
    _bluetoothHidTransport = BluetoothHidTransport(
      bluetoothProvider: bluetoothProvider,
      settingsProvider: settingsProvider,
    );
    _receiverWebSocketTransport = ReceiverWebSocketTransport(receiverService);
  }

  void update(
    SettingsProvider settings,
    BluetoothProvider bluetooth,
    ReceiverService receiver,
  ) {
    settingsProvider = settings;
    bluetoothProvider = bluetooth;
    receiverService = receiver;
    _bluetoothHidTransport = BluetoothHidTransport(
      bluetoothProvider: bluetoothProvider,
      settingsProvider: settingsProvider,
    );
    _receiverWebSocketTransport = ReceiverWebSocketTransport(receiverService);
    notifyListeners();
  }

  ControlTransport get activeTransport {
    final mode = settingsProvider.preferredConnectionMode;
    if (mode == 'bluetooth') {
      return _bluetoothHidTransport;
    } else if (mode == 'receiver') {
      return _receiverWebSocketTransport;
    } else {
      // 'auto' mode
      if (!bluetoothProvider.isHidSupported) {
        return _receiverWebSocketTransport;
      }
      return _bluetoothHidTransport;
    }
  }

  bool get isConnected => activeTransport.isConnected;

  String get connectionStatusName {
    final transport = activeTransport;
    
    // Check if transport-specific status applies, otherwise return status from it
    if (settingsProvider.preferredConnectionMode == 'auto') {
      if (!bluetoothProvider.isHidSupported) {
        return _receiverWebSocketTransport.connectionStatusName;
      }
      // If Bluetooth is supported but disconnected, and Receiver connects, what does auto display?
      // Since Bluetooth is selected as the default under Auto if supported, we check its status:
      if (_bluetoothHidTransport.isConnected) {
        return 'Bluetooth HID Connected';
      } else if (_receiverWebSocketTransport.isConnected) {
        return 'Receiver Connected';
      }
    }
    return transport.connectionStatusName;
  }
}
