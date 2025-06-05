import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../screens/practice_screen.dart';

class PracticeModeSelectionScreen extends ConsumerWidget {
  const PracticeModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32), // 黒板グリーン背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          "モードを選んでください",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildModeTile(
              title: 'Listening',
              icon: Icons.headphones,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.listening;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
            ),
            _buildModeTile(
              title: 'Overlapping',
              icon: Icons.surround_sound,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.overlapping;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
            ),
            _buildModeTile(
              title: 'Shadowing',
              icon: Icons.repeat,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.shadowing;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
            ),
            _buildModeTile(
              title: 'Recording Only',
              icon: Icons.mic,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.recordingOnly;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFFE8F5E9), // 明るい緑（ノート風）
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: Colors.green[900]),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
