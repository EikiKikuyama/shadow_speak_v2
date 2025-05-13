import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../providers/selected_material_provider.dart';
import 'listening_mode.dart';
import 'shadowing_mode.dart';
import 'overlapping_mode.dart';
import 'recording_only_mode.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(practiceModeProvider);
    final material = ref.watch(selectedMaterialProvider);

    // 🔒 nullチェック（nullの可能性がある場合）
// ❌ 以下の行を削除または修正

    // 🎯 各モードへ分岐
    switch (mode) {
      case PracticeMode.listening:
        return ListeningMode(material: material!);
      case PracticeMode.shadowing:
        return ShadowingMode(material: material!);
      case PracticeMode.overlapping:
        return OverlappingMode(material: material!);
      case PracticeMode.recordingOnly:
        return RecordingOnlyMode(material: material!);
    }
  }
}
