import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skill/flutter_skill.dart';
import 'package:provider/provider.dart';
import 'core/services/receiver_service.dart';
import 'core/services/transport_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/bluetooth/providers/bluetooth_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/widgets/main_dashboard.dart';

void main() {
  FlutterSkillBinding.ensureInitialized();

  // Setup release build safety error boundary
  if (kReleaseMode) {
    // Hide red screen of death and show a clean error UI
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please restart SlidePilot Pro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };

    // Present error details to console
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('Async error caught in release: $error');
      return true; // handled
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => ReceiverService()),
        ChangeNotifierProxyProvider3<SettingsProvider, BluetoothProvider, ReceiverService, TransportProvider>(
          create: (context) => TransportProvider(
            Provider.of<SettingsProvider>(context, listen: false),
            Provider.of<BluetoothProvider>(context, listen: false),
            Provider.of<ReceiverService>(context, listen: false),
          ),
          update: (context, settings, bluetooth, receiver, previous) {
            if (previous == null) {
              return TransportProvider(settings, bluetooth, receiver);
            }
            previous.update(settings, bluetooth, receiver);
            return previous;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'SlidePilot Pro',
            debugShowCheckedModeBanner: false,
            themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
            theme: settings.darkTheme ? AppTheme.darkTheme : ThemeData.light(useMaterial3: true),
            darkTheme: AppTheme.darkTheme,
            home: const MainDashboard(),
          );
        },
      ),
    );
  }
}
