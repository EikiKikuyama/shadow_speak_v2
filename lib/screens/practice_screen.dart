// lib/screens/practice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../screens/listening_mode.dart';
import '../screens/overlapping_mode.dart';
import '../screens/shadowing_mode.dart';
import '../screens/recording_only_mode.dart';


class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(practiceModeProvider);

    Widget modeWidget;
    switch (mode) {
      case PracticeMode.listening:
        modeWidget = const ListeningMode();
        break;
      case PracticeMode.overlapping:
        modeWidget = const OverlappingMode();
        break;
      case PracticeMode.shadowing:
        modeWidget = const ShadowingMode();
        break;
      case PracticeMode.recordingOnly:
        modeWidget = const RecordingOnlyMode();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('Current mode: ${mode.name}'),
    const SizedBox(height: 20),
    modeWidget,
  ],
),


    );
  }
}
