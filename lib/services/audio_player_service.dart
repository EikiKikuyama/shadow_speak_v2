import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService {
  late AudioPlayer _player = AudioPlayer();

  Future<void> reset() async {
    try {
      await _player.stop();
      _player = AudioPlayer(); // 完全な状態リセット
      // 👇 ここで play はしない！
      debugPrint('🔄 リセット完了（再生なし）');
    } catch (e) {
      debugPrint('❌ リセット失敗: $e');
    }
  }

  Future<void> play(String audioPath) async {
    if (audioPath.isEmpty) return;

    try {
      debugPrint('🎧 再生開始: $audioPath');
      await _player.play(AssetSource(audioPath));
    } catch (e) {
      debugPrint('❌ 再生失敗: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('❌ 停止失敗: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('❌ 一時停止失敗: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
