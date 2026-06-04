class AppConstants {
  // Method Channel
  static const String channelName = 'com.skillup.slidepilot_pro/bluetooth_hid';

  // SharedPreferences Keys
  static const String keyLastDeviceAddress = 'last_device_address';
  static const String keyLastDeviceName = 'last_device_name';
  static const String keyPointerSensitivity = 'pointer_sensitivity';
  static const String keyScrollSensitivity = 'scroll_sensitivity';
  static const String keyHapticFeedback = 'haptic_feedback';
  static const String keyAutoReconnect = 'auto_reconnect';
  static const String keyKeepScreenAwake = 'keep_screen_awake';
  static const String keyDarkTheme = 'dark_theme';
  static const String keyPresentationProfile = 'presentation_profile';

  // Default values
  static const double defaultPointerSensitivity = 1.0;
  static const double defaultScrollSensitivity = 1.0;
  static const bool defaultHapticFeedback = true;
  static const bool defaultAutoReconnect = true;
  static const bool defaultKeepScreenAwake = true;
  static const bool defaultDarkTheme = true;
  static const String defaultPresentationProfile = 'powerpoint_win';

  // Presentation Profiles
  static const Map<String, String> presentationProfiles = {
    'powerpoint_win': 'PowerPoint (Windows)',
    'powerpoint_mac': 'PowerPoint (macOS)',
    'google_slides': 'Google Slides',
    'keynote': 'Apple Keynote',
    'custom': 'Custom Keyboard Profile',
  };

  // Links
  static const String urlSkillUpCircle = 'https://skillupcircle.in';
  static const String urlDeveloperContact = 'https://htejas.com';
  static const String urlDonate = 'https://htejas.com/donate';
  static const String urlPrivacyPolicy = 'https://skillupcircle.in/privacy';
  static const String urlTermsOfUse = 'https://skillupcircle.in/terms';
}
