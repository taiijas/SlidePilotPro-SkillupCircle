import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _triggerHaptic(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticFeedback) {
      HapticFeedback.vibrate();
    }
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    _triggerHaptic(context);
    final Uri uri = Uri.parse(urlString);
    try {
      // Launch in external browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // App Logo Placeholder / Visual
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App Name & Tagline
            const Text(
              'SlidePilot Pro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Universal Bluetooth Presentation Controller',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Description Box
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'SlidePilot Pro is a free Android Bluetooth presentation controller and wireless trackpad that works without installing any software, drivers, or companion apps on the target computer.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Developer: SkillUp Circle',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons List
            _buildRowButton(
              context,
              label: 'Visit SkillUp Circle',
              icon: Icons.business,
              onPressed: () => _launchUrl(context, AppConstants.urlSkillUpCircle),
            ),
            const SizedBox(height: 12),
            _buildRowButton(
              context,
              label: 'Visit htejas.com',
              icon: Icons.public,
              onPressed: () => _launchUrl(context, AppConstants.urlDeveloperContact),
            ),
            const SizedBox(height: 12),
            _buildRowButton(
              context,
              label: 'Developer Connect',
              icon: Icons.alternate_email,
              onPressed: () => _launchUrl(context, AppConstants.urlDeveloperContact),
            ),
            const SizedBox(height: 12),
            _buildRowButton(
              context,
              label: 'Donate / Support Development',
              icon: Icons.favorite,
              iconColor: Colors.pinkAccent,
              onPressed: () => _launchUrl(context, AppConstants.urlDonate),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRowButton(
                    context,
                    label: 'Privacy Policy',
                    icon: Icons.privacy_tip,
                    onPressed: () => _launchUrl(context, AppConstants.urlPrivacyPolicy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRowButton(
                    context,
                    label: 'Terms of Use',
                    icon: Icons.description,
                    onPressed: () => _launchUrl(context, AppConstants.urlTermsOfUse),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRowButton(
              context,
              label: 'Email Support',
              icon: Icons.mail_outline,
              onPressed: () => _launchUrl(context, 'mailto:support@skillupcircle.com'),
            ),
            const SizedBox(height: 32),

            // Trademark & Version Info
            const Text(
              'Trademark Notice:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            const Text(
              'SkillUp Circle wordmark and logo are registered trademarks of SkillUp Ventures Pvt. Ltd.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRowButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardBg,
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.borderCol, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, color: iconColor ?? AppTheme.accentBlue, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
