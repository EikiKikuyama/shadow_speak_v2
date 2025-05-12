import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import 'practice_screen.dart'; // ← adjust path if needed

class PracticeModeSelectionScreen extends ConsumerWidget {
  const PracticeModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('モードを選んでください')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Shadowing'),
            leading: const Icon(Icons.repeat),
            onTap: () {
              ref.read(practiceModeProvider.notifier).state = PracticeMode.shadowing;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
  
}
