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

  // Getters
  bool get isInitialized => _isInitialized;
  double get pointerSensitivity => _pointerSensitivity;
  double get scrollSensitivity => _scrollSensitivity;
  bool get hapticFeedback => _hapticFeedback;
  bool get autoReconnect => _autoReconnect;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get darkTheme => _darkTheme;
  String get presentationProfile => _presentationProfile;

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

    await _prefs.remove(AppConstants.keyPointerSensitivity);
    await _prefs.remove(AppConstants.keyScrollSensitivity);
    await _prefs.remove(AppConstants.keyHapticFeedback);
    await _prefs.remove(AppConstants.keyAutoReconnect);
    await _prefs.remove(AppConstants.keyKeepScreenAwake);
    await _prefs.remove(AppConstants.keyDarkTheme);
    await _prefs.remove(AppConstants.keyPresentationProfile);
    await _prefs.remove(AppConstants.keyLastDeviceAddress);
    await _prefs.remove(AppConstants.keyLastDeviceName);

    _applyWakelock();
    notifyListeners();
  }
}
