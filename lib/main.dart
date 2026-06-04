import 'package:flutter/material.dart';
import 'package:flutter_skill/flutter_skill.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/bluetooth/providers/bluetooth_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/widgets/main_dashboard.dart';

void main() {
  FlutterSkillBinding.ensureInitialized();
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
