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
  static const String keyGestureMode = 'gesture_mode';
  static const String keyPlatformProfile = 'platform_profile';
  static const String keyMacosFourFingerSwipeOption = 'macos_four_finger_swipe_option';
  static const String keyGestureSensitivity = 'gesture_sensitivity';
  static const String keyPinchSensitivity = 'pinch_sensitivity';
  static const String keySwipeThreshold = 'swipe_threshold';
  static const String keyTapTimeout = 'tap_timeout';
  static const String keyLongPressDuration = 'long_press_duration';
  static const String keyThreeFingerTapAction = 'three_finger_tap_action';
  static const String keyThreeFingerTapCustomModifier = 'three_finger_tap_custom_modifier';
  static const String keyThreeFingerTapCustomKey = 'three_finger_tap_custom_key';
  static const String keyFourFingerTapAction = 'four_finger_tap_action';
  static const String keyFourFingerTapCustomModifier = 'four_finger_tap_custom_modifier';
  static const String keyFourFingerTapCustomKey = 'four_finger_tap_custom_key';
  static const String keyShowGestureGuide = 'show_gesture_guide';

  // Default values
  static const double defaultPointerSensitivity = 1.0;
  static const double defaultScrollSensitivity = 1.0;
  static const bool defaultHapticFeedback = true;
  static const bool defaultAutoReconnect = true;
  static const bool defaultKeepScreenAwake = true;
  static const bool defaultDarkTheme = true;
  static const String defaultPresentationProfile = 'powerpoint_win';
  static const String defaultGestureMode = 'trackpad';
  static const String defaultPlatformProfile = 'macos';
  static const String defaultMacosFourFingerSwipeOption = 'app_switching';
  static const double defaultGestureSensitivity = 1.0;
  static const double defaultPinchSensitivity = 1.0;
  static const double defaultSwipeThreshold = 30.0;
  static const int defaultTapTimeout = 250;
  static const int defaultLongPressDuration = 500;
  static const String defaultThreeFingerTapAction = 'middle_click';
  static const String defaultThreeFingerTapCustomModifier = '';
  static const String defaultThreeFingerTapCustomKey = '';
  static const String defaultFourFingerTapAction = 'none';
  static const String defaultFourFingerTapCustomModifier = '';
  static const String defaultFourFingerTapCustomKey = '';
  static const bool defaultShowGestureGuide = true;

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
  static const String urlPrivacyPolicy = 'https://skillupcircle.in/slidepilot-pro-privacy-policy/';
  static const String urlTermsOfUse = 'https://skillupcircle.in/slidepilot-pro-privacy-policy/#terms-of-use';
}
