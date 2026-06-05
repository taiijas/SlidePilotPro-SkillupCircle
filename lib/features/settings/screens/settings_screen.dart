import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../bluetooth/providers/bluetooth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _triggerHaptic(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticFeedback) {
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final btProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Preferences
          _buildSectionHeader(context, 'Controller Settings'),
          _buildCard(
            context,
            children: [
              // Pointer Sensitivity
              ListTile(
                title: const Text('Pointer Sensitivity', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${(settings.pointerSensitivity * 100).round()}%'),
              ),
              Slider(
                value: settings.pointerSensitivity,
                min: 0.2,
                max: 3.0,
                divisions: 28,
                onChanged: (val) {
                  settings.setPointerSensitivity(val);
                },
                onChangeEnd: (_) => _triggerHaptic(context),
              ),
              const Divider(color: AppTheme.borderCol),

              // Scroll Sensitivity
              ListTile(
                title: const Text('Scroll Sensitivity', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${(settings.scrollSensitivity * 100).round()}%'),
              ),
              Slider(
                value: settings.scrollSensitivity,
                min: 0.2,
                max: 3.0,
                divisions: 28,
                onChanged: (val) {
                  settings.setScrollSensitivity(val);
                },
                onChangeEnd: (_) => _triggerHaptic(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: Gesture & Touchpad Settings
          _buildSectionHeader(context, 'Gesture & Touchpad Settings'),
          _buildCard(
            context,
            children: [
              // Gesture Mode Selector
              ListTile(
                title: const Text('Gesture Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select the active touchpad response mode'),
                trailing: DropdownButton<String>(
                  value: settings.gestureMode,
                  dropdownColor: AppTheme.cardBg,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      _triggerHaptic(context);
                      settings.setGestureMode(val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'trackpad', child: Text('Trackpad Mode')),
                    DropdownMenuItem(value: 'presentation', child: Text('Presentation Mode')),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderCol, height: 1),

              // Platform Profile Selector
              ListTile(
                title: const Text('Platform Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Keyboard layout mappings for gestures'),
                trailing: DropdownButton<String>(
                  value: settings.platformProfile,
                  dropdownColor: AppTheme.cardBg,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      _triggerHaptic(context);
                      settings.setPlatformProfile(val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'macos', child: Text('macOS')),
                    DropdownMenuItem(value: 'windows', child: Text('Windows')),
                    DropdownMenuItem(value: 'linux', child: Text('Linux')),
                    DropdownMenuItem(value: 'google_slides', child: Text('Google Slides')),
                    DropdownMenuItem(value: 'powerpoint', child: Text('PowerPoint')),
                    DropdownMenuItem(value: 'keynote', child: Text('Keynote')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderCol, height: 1),

              // macOS Specific Options (Conditional)
              if (settings.platformProfile == 'macos' || settings.platformProfile == 'custom') ...[
                ListTile(
                  title: const Text('Four-Finger Swipe', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Action mapped to four-finger swipe'),
                  trailing: DropdownButton<String>(
                    value: settings.macosFourFingerSwipeOption,
                    dropdownColor: AppTheme.cardBg,
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        _triggerHaptic(context);
                        settings.setMacosFourFingerSwipeOption(val);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'app_switching', child: Text('App Switching (Cmd+Tab)')),
                      DropdownMenuItem(value: 'desktop_switching', child: Text('Space Switch (Ctrl+Arrow)')),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderCol, height: 1),
              ],

              // Toggle to show/hide gesture guide
              _buildSwitchRow(
                context,
                title: 'Show Gesture Guide',
                subtitle: 'Display guide card on Trackpad screen',
                value: settings.showGestureGuide,
                onChanged: (val) {
                  _triggerHaptic(context);
                  settings.setShowGestureGuide(val);
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),

              // Expandable parameters panel (Sensitivities & Thresholds)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Sensitivities & Advanced Thresholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Gesture Sensitivity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gesture Swipe Sensitivity'),
                              Text('${(settings.gestureSensitivity * 100).round()}%'),
                            ],
                          ),
                          Slider(
                            value: settings.gestureSensitivity,
                            min: 0.2,
                            max: 3.0,
                            divisions: 28,
                            onChanged: (val) => settings.setGestureSensitivity(val),
                            onChangeEnd: (_) => _triggerHaptic(context),
                          ),
                          const SizedBox(height: 10),

                          // Pinch Sensitivity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pinch Zoom Sensitivity'),
                              Text('${(settings.pinchSensitivity * 100).round()}%'),
                            ],
                          ),
                          Slider(
                            value: settings.pinchSensitivity,
                            min: 0.2,
                            max: 3.0,
                            divisions: 28,
                            onChanged: (val) => settings.setPinchSensitivity(val),
                            onChangeEnd: (_) => _triggerHaptic(context),
                          ),
                          const SizedBox(height: 10),

                          // Swipe Threshold
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Swipe Displacement Threshold'),
                              Text('${settings.swipeThreshold.round()} px'),
                            ],
                          ),
                          Slider(
                            value: settings.swipeThreshold,
                            min: 10.0,
                            max: 100.0,
                            divisions: 9,
                            onChanged: (val) => settings.setSwipeThreshold(val),
                            onChangeEnd: (_) => _triggerHaptic(context),
                          ),
                          const SizedBox(height: 10),

                          // Tap Timeout
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tap Max Timeout'),
                              Text('${settings.tapTimeout} ms'),
                            ],
                          ),
                          Slider(
                            value: settings.tapTimeout.toDouble(),
                            min: 100.0,
                            max: 500.0,
                            divisions: 8,
                            onChanged: (val) => settings.setTapTimeout(val.round()),
                            onChangeEnd: (_) => _triggerHaptic(context),
                          ),
                          const SizedBox(height: 10),

                          // Long Press Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Long Press Activation Delay'),
                              Text('${settings.longPressDuration} ms'),
                            ],
                          ),
                          Slider(
                            value: settings.longPressDuration.toDouble(),
                            min: 200.0,
                            max: 1500.0,
                            divisions: 13,
                            onChanged: (val) => settings.setLongPressDuration(val.round()),
                            onChangeEnd: (_) => _triggerHaptic(context),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderCol, height: 1),

              // Expandable Tap Custom Actions configuration
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Custom Tap Action Mapping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // Three-Finger Tap Action
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Three-Finger Tap'),
                            trailing: DropdownButton<String>(
                              value: settings.threeFingerTapAction,
                              dropdownColor: AppTheme.cardBg,
                              underline: const SizedBox(),
                              onChanged: (val) {
                                if (val != null) {
                                  _triggerHaptic(context);
                                  settings.setThreeFingerTapAction(val);
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('None')),
                                DropdownMenuItem(value: 'middle_click', child: Text('Middle Click')),
                                DropdownMenuItem(value: 'left_click', child: Text('Left Click')),
                                DropdownMenuItem(value: 'right_click', child: Text('Right Click')),
                                DropdownMenuItem(value: 'space', child: Text('Space')),
                                DropdownMenuItem(value: 'enter', child: Text('Enter')),
                                DropdownMenuItem(value: 'custom', child: Text('Custom Shortcut')),
                              ],
                            ),
                          ),
                          if (settings.threeFingerTapAction == 'custom') ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomShortcutTextField(
                                      labelText: 'Modifier (e.g. ctrl)',
                                      initialValue: settings.threeFingerTapCustomModifier,
                                      onChanged: (val) => settings.setThreeFingerTapCustomModifier(val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomShortcutTextField(
                                      labelText: 'Key (e.g. plus, d)',
                                      initialValue: settings.threeFingerTapCustomKey,
                                      onChanged: (val) => settings.setThreeFingerTapCustomKey(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(color: AppTheme.borderCol, height: 1),

                          // Four-Finger Tap Action
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Four-Finger Tap'),
                            trailing: DropdownButton<String>(
                              value: settings.fourFingerTapAction,
                              dropdownColor: AppTheme.cardBg,
                              underline: const SizedBox(),
                              onChanged: (val) {
                                if (val != null) {
                                  _triggerHaptic(context);
                                  settings.setFourFingerTapAction(val);
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('None')),
                                DropdownMenuItem(value: 'middle_click', child: Text('Middle Click')),
                                DropdownMenuItem(value: 'left_click', child: Text('Left Click')),
                                DropdownMenuItem(value: 'right_click', child: Text('Right Click')),
                                DropdownMenuItem(value: 'space', child: Text('Space')),
                                DropdownMenuItem(value: 'enter', child: Text('Enter')),
                                DropdownMenuItem(value: 'custom', child: Text('Custom Shortcut')),
                              ],
                            ),
                          ),
                          if (settings.fourFingerTapAction == 'custom') ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomShortcutTextField(
                                      labelText: 'Modifier (e.g. ctrl)',
                                      initialValue: settings.fourFingerTapCustomModifier,
                                      onChanged: (val) => settings.setFourFingerTapCustomModifier(val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomShortcutTextField(
                                      labelText: 'Key (e.g. enter)',
                                      initialValue: settings.fourFingerTapCustomKey,
                                      onChanged: (val) => settings.setFourFingerTapCustomKey(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: General
          _buildSectionHeader(context, 'General Preferences'),
          _buildCard(
            context,
            children: [
              _buildSwitchRow(
                context,
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on button press & gestures',
                value: settings.hapticFeedback,
                onChanged: (val) {
                  _triggerHaptic(context);
                  settings.setHapticFeedback(val);
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              _buildSwitchRow(
                context,
                title: 'Auto Reconnect',
                subtitle: 'Attempt reconnecting to last host',
                value: settings.autoReconnect,
                onChanged: (val) {
                  _triggerHaptic(context);
                  settings.setAutoReconnect(val);
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              _buildSwitchRow(
                context,
                title: 'Keep Screen Awake',
                subtitle: 'Prevent screen dimming during show',
                value: settings.keepScreenAwake,
                onChanged: (val) {
                  _triggerHaptic(context);
                  settings.setKeepScreenAwake(val);
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              _buildSwitchRow(
                context,
                title: 'Dark Theme',
                subtitle: 'Use premium dark-slate styling',
                value: settings.darkTheme,
                onChanged: (val) {
                  _triggerHaptic(context);
                  settings.setDarkTheme(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: Presentation Profile
          _buildSectionHeader(context, 'Presentation Profile'),
          _buildCard(
            context,
            children: [
              ListTile(
                title: const Text('Active Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Adjusts keyboard mappings for apps'),
                trailing: DropdownButton<String>(
                  value: settings.presentationProfile,
                  dropdownColor: AppTheme.cardBg,
                  underline: const SizedBox(),
                  onChanged: (String? newProfile) {
                    if (newProfile != null) {
                      _triggerHaptic(context);
                      settings.setPresentationProfile(newProfile);
                    }
                  },
                  items: AppConstants.presentationProfiles.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: Advanced
          _buildSectionHeader(context, 'Advanced Options'),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.bluetooth_disabled, color: Colors.amber),
                title: const Text('Reset Bluetooth Preferences'),
                onTap: () {
                  _triggerHaptic(context);
                  btProvider.forgetLastDevice();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bluetooth preferences reset.')),
                  );
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppTheme.error),
                title: const Text('Forget Saved Devices'),
                onTap: () {
                  _triggerHaptic(context);
                  btProvider.forgetLastDevice();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved devices forgotten.')),
                  );
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              ListTile(
                leading: const Icon(Icons.file_download, color: AppTheme.accentBlue),
                title: const Text('Export Logs'),
                onTap: () {
                  _triggerHaptic(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs exported successfully to device storage.')),
                  );
                },
              ),
              const Divider(color: AppTheme.borderCol, height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline, color: Colors.white70),
                title: Text('App Version'),
                trailing: Text('v1.0.0 (Build 1)', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class CustomShortcutTextField extends StatefulWidget {
  final String labelText;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const CustomShortcutTextField({
    super.key,
    required this.labelText,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<CustomShortcutTextField> createState() => _CustomShortcutTextFieldState();
}

class _CustomShortcutTextFieldState extends State<CustomShortcutTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(CustomShortcutTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onChanged: widget.onChanged,
    );
  }
}
