import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadow_speak_v2/models/material_model.dart';
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
    final material = ref.watch(selectedMaterialProvider);
    final mode = ref.watch(practiceModeProvider);

    // ❗️教材が未選択だった場合はエラー防止
    if (material == null || material.scriptPath.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("⚠ 教材が選択されていません")),
      );
    }

    switch (mode) {
      case PracticeMode.listening:
        return ListeningMode(material: material);
      case PracticeMode.shadowing:
        return ShadowingMode(material: material);
      case PracticeMode.overlapping:
        return OverlappingMode(material: material);
      case PracticeMode.recordingOnly:
        return RecordingOnlyMode(material: material);
      default:
        return const Center(child: Text("⚠ モードが選択されていません"));
    }
  }
}
