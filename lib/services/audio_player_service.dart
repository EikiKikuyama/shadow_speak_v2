import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  /// 汎用再生（Listeningモード用） → asset or URL
  Future<void> play(String sourcePath) async {
    await _player.stop(); // 再生中なら停止
    await _player.play(AssetSource(sourcePath));
  }

  /// 録音ファイルなどローカル再生（Shadowingモードなど用）
  Future<void> playLocalFile(String filePath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> reset() async {
    await _player.seek(Duration.zero);
  }

  void dispose() {
    _player.dispose();
  }

  /// ✅ assets/audio/ 配下の音声ファイルを一時保存し、ファイルパスを返す
  // utils/audio_player_service.dart 内
  Future<String> copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load('assets/$assetPath'); // ← 修正！
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split("/").last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}
