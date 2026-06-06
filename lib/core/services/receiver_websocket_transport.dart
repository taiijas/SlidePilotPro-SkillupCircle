import 'control_transport.dart';
import 'receiver_service.dart';

class ReceiverWebSocketTransport implements ControlTransport {
  final ReceiverService receiverService;

  ReceiverWebSocketTransport(this.receiverService);

  String _normalizeKey(String key) {
    final norm = key.toLowerCase().trim();
    if (norm == 'left_arrow') return 'left';
    if (norm == 'right_arrow') return 'right';
    if (norm == 'up_arrow') return 'up';
    if (norm == 'down_arrow') return 'down';
    return norm;
  }

  List<String> _parseShortcut(String modifier, String key) {
    final List<String> list = [];
    if (modifier.isNotEmpty) {
      final parts = modifier.toLowerCase().split('+');
      for (var part in parts) {
        part = part.trim();
        if (part == 'cmd' || part == 'meta' || part == 'win') {
          list.add('win');
        } else if (part == 'ctrl' || part == 'control') {
          list.add('ctrl');
        } else if (part == 'alt' || part == 'opt' || part == 'option') {
          list.add('alt');
        } else if (part == 'shift') {
          list.add('shift');
        } else if (part.isNotEmpty) {
          list.add(part);
        }
      }
    }
    list.add(_normalizeKey(key));
    return list;
  }

  String _getButtonString(int button) {
    switch (button) {
      case 0:
        return 'left';
      case 1:
        return 'right';
      case 2:
        return 'middle';
      default:
        return 'left';
    }
  }

  @override
  Future<void> sendKeyboardKey(String modifier, String key) async {
    if (modifier.isEmpty) {
      await receiverService.sendKeyboardKey(_normalizeKey(key));
    } else {
      final keys = _parseShortcut(modifier, key);
      await receiverService.sendKeyboardShortcut(keys);
    }
  }

  @override
  Future<void> sendKeyboardShortcut(String modifier, String key) async {
    final keys = _parseShortcut(modifier, key);
    await receiverService.sendKeyboardShortcut(keys);
  }

  @override
  Future<void> sendMouseMove(int dx, int dy) async {
    await receiverService.sendMouseMove(dx, dy);
  }

  @override
  Future<void> sendMouseButton(int button, bool isPressed) async {
    final btn = _getButtonString(button);
    if (isPressed) {
      await receiverService.sendMouseButtonDown(btn);
    } else {
      await receiverService.sendMouseButtonUp(btn);
    }
  }

  @override
  Future<void> sendLeftClick() async {
    await receiverService.sendMouseClick('left');
  }

  @override
  Future<void> sendMouseScroll(int delta) async {
    await receiverService.sendMouseScroll(delta);
  }

  @override
  Future<void> sendGesture(String action, String profile) async {
    await receiverService.sendGesture(action, profile);
  }

  @override
  bool get isConnected => receiverService.isConnected && receiverService.pairingStatus == 'Paired';

  @override
  String get connectionStatusName {
    if (receiverService.isConnecting || receiverService.pairingStatus == 'Pairing') {
      return 'Receiver Waiting';
    }
    if (receiverService.isConnected && receiverService.pairingStatus == 'Paired') {
      return 'Receiver Connected';
    }
    return 'Disconnected';
  }
}
