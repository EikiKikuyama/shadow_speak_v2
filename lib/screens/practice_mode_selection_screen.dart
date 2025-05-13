import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../screens/practice_screen.dart';

class PracticeModeSelectionScreen extends ConsumerWidget {
  const PracticeModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("モードを選んでください"),
        leading: BackButton(), // 🔙 戻るボタンを追加
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Listening'),
            leading: const Icon(Icons.headphones),
            onTap: () {
              ref.read(practiceModeProvider.notifier).state =
                  PracticeMode.listening;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PracticeScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Overlapping'),
            leading: const Icon(Icons.surround_sound),
            onTap: () {
              ref.read(practiceModeProvider.notifier).state =
                  PracticeMode.overlapping;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PracticeScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Shadowing'),
            leading: const Icon(Icons.repeat),
            onTap: () {
              ref.read(practiceModeProvider.notifier).state =
                  PracticeMode.shadowing;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PracticeScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Recording Only'),
            leading: const Icon(Icons.mic),
            onTap: () {
              ref.read(practiceModeProvider.notifier).state =
                  PracticeMode.recordingOnly;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PracticeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
