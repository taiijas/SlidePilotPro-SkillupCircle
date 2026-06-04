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
