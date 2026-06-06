abstract class ControlTransport {
  Future<void> sendKeyboardKey(String modifier, String key);
  Future<void> sendKeyboardShortcut(String modifier, String key);
  Future<void> sendMouseMove(int dx, int dy);
  Future<void> sendMouseButton(int button, bool isPressed);
  Future<void> sendLeftClick();
  Future<void> sendMouseScroll(int delta);
  Future<void> sendGesture(String action, String profile);
  bool get isConnected;
  String get connectionStatusName;
}
