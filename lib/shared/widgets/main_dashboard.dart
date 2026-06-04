import 'package:flutter/material.dart';
import '../../features/bluetooth/screens/connect_screen.dart';
import '../../features/presenter/screens/presenter_screen.dart';
import '../../features/trackpad/screens/trackpad_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/about/screens/about_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ConnectScreen(),
          PresenterScreen(),
          TrackpadScreen(),
          SettingsScreen(),
          AboutScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            activeIcon: Icon(Icons.bluetooth, color: Colors.blueAccent),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.slideshow),
            activeIcon: Icon(Icons.slideshow, color: Colors.blueAccent),
            label: 'Presenter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mouse_outlined),
            activeIcon: Icon(Icons.mouse, color: Colors.blueAccent),
            label: 'Trackpad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings, color: Colors.blueAccent),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info, color: Colors.blueAccent),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
