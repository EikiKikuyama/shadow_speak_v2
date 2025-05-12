// lib/providers/practice_mode_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 練習モードを列挙型で定義
enum PracticeMode {
  listening,
  overlapping,
  shadowing,
  recordingOnly,
}

// 状態として現在のモードを保持
final practiceModeProvider = StateProvider<PracticeMode>((ref) {
  return PracticeMode.listening; // 初期モード（仮）
});
