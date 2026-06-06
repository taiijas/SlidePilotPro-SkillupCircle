import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/app_constants.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Configuration Fields
  double _pointerSensitivity = AppConstants.defaultPointerSensitivity;
  double _scrollSensitivity = AppConstants.defaultScrollSensitivity;
  bool _hapticFeedback = AppConstants.defaultHapticFeedback;
  bool _autoReconnect = AppConstants.defaultAutoReconnect;
  bool _keepScreenAwake = AppConstants.defaultKeepScreenAwake;
  bool _darkTheme = AppConstants.defaultDarkTheme;
  String _presentationProfile = AppConstants.defaultPresentationProfile;
  String _gestureMode = AppConstants.defaultGestureMode;
  String _platformProfile = AppConstants.defaultPlatformProfile;
  String _macosFourFingerSwipeOption = AppConstants.defaultMacosFourFingerSwipeOption;
  double _gestureSensitivity = AppConstants.defaultGestureSensitivity;
  double _pinchSensitivity = AppConstants.defaultPinchSensitivity;
  double _swipeThreshold = AppConstants.defaultSwipeThreshold;
  int _tapTimeout = AppConstants.defaultTapTimeout;
  int _longPressDuration = AppConstants.defaultLongPressDuration;
  String _threeFingerTapAction = AppConstants.defaultThreeFingerTapAction;
  String _threeFingerTapCustomModifier = AppConstants.defaultThreeFingerTapCustomModifier;
  String _threeFingerTapCustomKey = AppConstants.defaultThreeFingerTapCustomKey;
  String _fourFingerTapAction = AppConstants.defaultFourFingerTapAction;
  String _fourFingerTapCustomModifier = AppConstants.defaultFourFingerTapCustomModifier;
  String _fourFingerTapCustomKey = AppConstants.defaultFourFingerTapCustomKey;
  bool _showGestureGuide = AppConstants.defaultShowGestureGuide;
  String _preferredConnectionMode = AppConstants.defaultConnectionMode;
  int _receiverTimeout = AppConstants.defaultReceiverTimeout;

  // Getters
  bool get isInitialized => _isInitialized;
  double get pointerSensitivity => _pointerSensitivity;
  double get scrollSensitivity => _scrollSensitivity;
  bool get hapticFeedback => _hapticFeedback;
  bool get autoReconnect => _autoReconnect;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get darkTheme => _darkTheme;
  String get presentationProfile => _presentationProfile;
  String get gestureMode => _gestureMode;
  String get platformProfile => _platformProfile;
  String get macosFourFingerSwipeOption => _macosFourFingerSwipeOption;
  double get gestureSensitivity => _gestureSensitivity;
  double get pinchSensitivity => _pinchSensitivity;
  double get swipeThreshold => _swipeThreshold;
  int get tapTimeout => _tapTimeout;
  int get longPressDuration => _longPressDuration;
  String get threeFingerTapAction => _threeFingerTapAction;
  String get threeFingerTapCustomModifier => _threeFingerTapCustomModifier;
  String get threeFingerTapCustomKey => _threeFingerTapCustomKey;
  String get fourFingerTapAction => _fourFingerTapAction;
  String get fourFingerTapCustomModifier => _fourFingerTapCustomModifier;
  String get fourFingerTapCustomKey => _fourFingerTapCustomKey;
  bool get showGestureGuide => _showGestureGuide;
  String get preferredConnectionMode => _preferredConnectionMode;
  int get receiverTimeout => _receiverTimeout;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _pointerSensitivity = _prefs.getDouble(AppConstants.keyPointerSensitivity) ??
        AppConstants.defaultPointerSensitivity;
    _scrollSensitivity = _prefs.getDouble(AppConstants.keyScrollSensitivity) ??
        AppConstants.defaultScrollSensitivity;
    _hapticFeedback = _prefs.getBool(AppConstants.keyHapticFeedback) ??
        AppConstants.defaultHapticFeedback;
    _autoReconnect = _prefs.getBool(AppConstants.keyAutoReconnect) ??
        AppConstants.defaultAutoReconnect;
    _keepScreenAwake = _prefs.getBool(AppConstants.keyKeepScreenAwake) ??
        AppConstants.defaultKeepScreenAwake;
    _darkTheme = _prefs.getBool(AppConstants.keyDarkTheme) ??
        AppConstants.defaultDarkTheme;
    _presentationProfile = _prefs.getString(AppConstants.keyPresentationProfile) ??
        AppConstants.defaultPresentationProfile;
    _gestureMode = _prefs.getString(AppConstants.keyGestureMode) ??
        AppConstants.defaultGestureMode;
    _platformProfile = _prefs.getString(AppConstants.keyPlatformProfile) ??
        AppConstants.defaultPlatformProfile;
    _macosFourFingerSwipeOption = _prefs.getString(AppConstants.keyMacosFourFingerSwipeOption) ??
        AppConstants.defaultMacosFourFingerSwipeOption;
    _gestureSensitivity = _prefs.getDouble(AppConstants.keyGestureSensitivity) ??
        AppConstants.defaultGestureSensitivity;
    _pinchSensitivity = _prefs.getDouble(AppConstants.keyPinchSensitivity) ??
        AppConstants.defaultPinchSensitivity;
    _swipeThreshold = _prefs.getDouble(AppConstants.keySwipeThreshold) ??
        AppConstants.defaultSwipeThreshold;
    _tapTimeout = _prefs.getInt(AppConstants.keyTapTimeout) ??
        AppConstants.defaultTapTimeout;
    _longPressDuration = _prefs.getInt(AppConstants.keyLongPressDuration) ??
        AppConstants.defaultLongPressDuration;
    _threeFingerTapAction = _prefs.getString(AppConstants.keyThreeFingerTapAction) ??
        AppConstants.defaultThreeFingerTapAction;
    _threeFingerTapCustomModifier = _prefs.getString(AppConstants.keyThreeFingerTapCustomModifier) ??
        AppConstants.defaultThreeFingerTapCustomModifier;
    _threeFingerTapCustomKey = _prefs.getString(AppConstants.keyThreeFingerTapCustomKey) ??
        AppConstants.defaultThreeFingerTapCustomKey;
    _fourFingerTapAction = _prefs.getString(AppConstants.keyFourFingerTapAction) ??
        AppConstants.defaultFourFingerTapAction;
    _fourFingerTapCustomModifier = _prefs.getString(AppConstants.keyFourFingerTapCustomModifier) ??
        AppConstants.defaultFourFingerTapCustomModifier;
    _fourFingerTapCustomKey = _prefs.getString(AppConstants.keyFourFingerTapCustomKey) ??
        AppConstants.defaultFourFingerTapCustomKey;
    _showGestureGuide = _prefs.getBool(AppConstants.keyShowGestureGuide) ??
        AppConstants.defaultShowGestureGuide;
    _preferredConnectionMode = _prefs.getString(AppConstants.keyPreferredConnectionMode) ??
        AppConstants.defaultConnectionMode;
    _receiverTimeout = _prefs.getInt(AppConstants.keyReceiverTimeout) ??
        AppConstants.defaultReceiverTimeout;

    _applyWakelock();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setPointerSensitivity(double value) async {
    _pointerSensitivity = value;
    await _prefs.setDouble(AppConstants.keyPointerSensitivity, value);
    notifyListeners();
  }

  Future<void> setScrollSensitivity(double value) async {
    _scrollSensitivity = value;
    await _prefs.setDouble(AppConstants.keyScrollSensitivity, value);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    await _prefs.setBool(AppConstants.keyHapticFeedback, value);
    notifyListeners();
  }

  Future<void> setAutoReconnect(bool value) async {
    _autoReconnect = value;
    await _prefs.setBool(AppConstants.keyAutoReconnect, value);
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool value) async {
    _keepScreenAwake = value;
    await _prefs.setBool(AppConstants.keyKeepScreenAwake, value);
    _applyWakelock();
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    await _prefs.setBool(AppConstants.keyDarkTheme, value);
    notifyListeners();
  }

  Future<void> setPresentationProfile(String profile) async {
    _presentationProfile = profile;
    await _prefs.setString(AppConstants.keyPresentationProfile, profile);
    notifyListeners();
  }

  Future<void> setGestureMode(String value) async {
    _gestureMode = value;
    await _prefs.setString(AppConstants.keyGestureMode, value);
    notifyListeners();
  }

  Future<void> setPlatformProfile(String value) async {
    _platformProfile = value;
    await _prefs.setString(AppConstants.keyPlatformProfile, value);
    notifyListeners();
  }

  Future<void> setMacosFourFingerSwipeOption(String value) async {
    _macosFourFingerSwipeOption = value;
    await _prefs.setString(AppConstants.keyMacosFourFingerSwipeOption, value);
    notifyListeners();
  }

  Future<void> setGestureSensitivity(double value) async {
    _gestureSensitivity = value;
    await _prefs.setDouble(AppConstants.keyGestureSensitivity, value);
    notifyListeners();
  }

  Future<void> setPinchSensitivity(double value) async {
    _pinchSensitivity = value;
    await _prefs.setDouble(AppConstants.keyPinchSensitivity, value);
    notifyListeners();
  }

  Future<void> setSwipeThreshold(double value) async {
    _swipeThreshold = value;
    await _prefs.setDouble(AppConstants.keySwipeThreshold, value);
    notifyListeners();
  }

  Future<void> setTapTimeout(int value) async {
    _tapTimeout = value;
    await _prefs.setInt(AppConstants.keyTapTimeout, value);
    notifyListeners();
  }

  Future<void> setLongPressDuration(int value) async {
    _longPressDuration = value;
    await _prefs.setInt(AppConstants.keyLongPressDuration, value);
    notifyListeners();
  }

  Future<void> setThreeFingerTapAction(String value) async {
    _threeFingerTapAction = value;
    await _prefs.setString(AppConstants.keyThreeFingerTapAction, value);
    notifyListeners();
  }

  Future<void> setThreeFingerTapCustomModifier(String value) async {
    _threeFingerTapCustomModifier = value;
    await _prefs.setString(AppConstants.keyThreeFingerTapCustomModifier, value);
    notifyListeners();
  }

  Future<void> setThreeFingerTapCustomKey(String value) async {
    _threeFingerTapCustomKey = value;
    await _prefs.setString(AppConstants.keyThreeFingerTapCustomKey, value);
    notifyListeners();
  }

  Future<void> setFourFingerTapAction(String value) async {
    _fourFingerTapAction = value;
    await _prefs.setString(AppConstants.keyFourFingerTapAction, value);
    notifyListeners();
  }

  Future<void> setFourFingerTapCustomModifier(String value) async {
    _fourFingerTapCustomModifier = value;
    await _prefs.setString(AppConstants.keyFourFingerTapCustomModifier, value);
    notifyListeners();
  }

  Future<void> setFourFingerTapCustomKey(String value) async {
    _fourFingerTapCustomKey = value;
    await _prefs.setString(AppConstants.keyFourFingerTapCustomKey, value);
    notifyListeners();
  }

  Future<void> setShowGestureGuide(bool value) async {
    _showGestureGuide = value;
    await _prefs.setBool(AppConstants.keyShowGestureGuide, value);
    notifyListeners();
  }

  Future<void> setPreferredConnectionMode(String value) async {
    _preferredConnectionMode = value;
    await _prefs.setString(AppConstants.keyPreferredConnectionMode, value);
    notifyListeners();
  }

  Future<void> setReceiverTimeout(int value) async {
    _receiverTimeout = value;
    await _prefs.setInt(AppConstants.keyReceiverTimeout, value);
    notifyListeners();
  }

  void _applyWakelock() {
    try {
      if (_keepScreenAwake) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('Wakelock toggle failed: $e');
    }
  }

  Future<void> resetAll() async {
    _pointerSensitivity = AppConstants.defaultPointerSensitivity;
    _scrollSensitivity = AppConstants.defaultScrollSensitivity;
    _hapticFeedback = AppConstants.defaultHapticFeedback;
    _autoReconnect = AppConstants.defaultAutoReconnect;
    _keepScreenAwake = AppConstants.defaultKeepScreenAwake;
    _darkTheme = AppConstants.defaultDarkTheme;
    _presentationProfile = AppConstants.defaultPresentationProfile;
    _gestureMode = AppConstants.defaultGestureMode;
    _platformProfile = AppConstants.defaultPlatformProfile;
    _macosFourFingerSwipeOption = AppConstants.defaultMacosFourFingerSwipeOption;
    _gestureSensitivity = AppConstants.defaultGestureSensitivity;
    _pinchSensitivity = AppConstants.defaultPinchSensitivity;
    _swipeThreshold = AppConstants.defaultSwipeThreshold;
    _tapTimeout = AppConstants.defaultTapTimeout;
    _longPressDuration = AppConstants.defaultLongPressDuration;
    _threeFingerTapAction = AppConstants.defaultThreeFingerTapAction;
    _threeFingerTapCustomModifier = AppConstants.defaultThreeFingerTapCustomModifier;
    _threeFingerTapCustomKey = AppConstants.defaultThreeFingerTapCustomKey;
    _fourFingerTapAction = AppConstants.defaultFourFingerTapAction;
    _fourFingerTapCustomModifier = AppConstants.defaultFourFingerTapCustomModifier;
    _fourFingerTapCustomKey = AppConstants.defaultFourFingerTapCustomKey;
    _showGestureGuide = AppConstants.defaultShowGestureGuide;
    _preferredConnectionMode = AppConstants.defaultConnectionMode;
    _receiverTimeout = AppConstants.defaultReceiverTimeout;

    await _prefs.remove(AppConstants.keyPointerSensitivity);
    await _prefs.remove(AppConstants.keyScrollSensitivity);
    await _prefs.remove(AppConstants.keyHapticFeedback);
    await _prefs.remove(AppConstants.keyAutoReconnect);
    await _prefs.remove(AppConstants.keyKeepScreenAwake);
    await _prefs.remove(AppConstants.keyDarkTheme);
    await _prefs.remove(AppConstants.keyPresentationProfile);
    await _prefs.remove(AppConstants.keyGestureMode);
    await _prefs.remove(AppConstants.keyPlatformProfile);
    await _prefs.remove(AppConstants.keyMacosFourFingerSwipeOption);
    await _prefs.remove(AppConstants.keyGestureSensitivity);
    await _prefs.remove(AppConstants.keyPinchSensitivity);
    await _prefs.remove(AppConstants.keySwipeThreshold);
    await _prefs.remove(AppConstants.keyTapTimeout);
    await _prefs.remove(AppConstants.keyLongPressDuration);
    await _prefs.remove(AppConstants.keyThreeFingerTapAction);
    await _prefs.remove(AppConstants.keyThreeFingerTapCustomModifier);
    await _prefs.remove(AppConstants.keyThreeFingerTapCustomKey);
    await _prefs.remove(AppConstants.keyFourFingerTapAction);
    await _prefs.remove(AppConstants.keyFourFingerTapCustomModifier);
    await _prefs.remove(AppConstants.keyFourFingerTapCustomKey);
    await _prefs.remove(AppConstants.keyShowGestureGuide);
    await _prefs.remove(AppConstants.keyLastDeviceAddress);
    await _prefs.remove(AppConstants.keyLastDeviceName);
    await _prefs.remove(AppConstants.keyPreferredConnectionMode);
    await _prefs.remove(AppConstants.keyReceiverTimeout);

    _applyWakelock();
    notifyListeners();
  }
}
