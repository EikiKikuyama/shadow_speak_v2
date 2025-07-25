import 'package:flutter/material.dart';
import 'level_home_screen.dart';
import 'recording_history_screen.dart';
import 'progress_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LevelHomeScreen(), // ホーム画面（レベル選択）
    const RecordingHistoryScreen(), // 録音履歴
    const ProgressScreen(), // 進捗
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: '進捗',
          ),
        ],
      ),
    );
  }
}
