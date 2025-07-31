import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'level_home_screen.dart';
import 'recording_history_screen.dart';
import 'progress_screen.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LevelHomeScreen(),
    const RecordingHistoryScreen(),
    const ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: isDarkMode ? const Color(0xFF0C1A3E) : Colors.white,
        selectedItemColor: isDarkMode ? Colors.white : Colors.deepPurple,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '進捗'),
        ],
      ),
    );
  }
}
