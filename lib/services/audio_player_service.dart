import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  // ✅ duration を内部で保持
  Duration? _duration;
  Duration? get totalDuration => _duration;

  // ✅ 再生位置を外部に通知する StreamController
  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  AudioPlayerService() {
    // ✅ duration 更新
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
    });

    // ✅ 再生位置を通知
    _player.onPositionChanged.listen((position) {
      _positionController.add(position);
    });
  }

  /// ✅ アセット音声再生（Listeningモード等）
  Future<void> play(String sourcePath) async {
    await _player.stop();
    await _player.play(AssetSource(sourcePath));
  }

  /// ✅ ローカルファイル再生（録音ファイル等）
  Future<void> playLocalFile(String filePath) async {
    try {
      await _player.stop();
      await _player.setSource(DeviceFileSource(filePath));
      await _player.resume();
    } catch (e) {
      debugPrint("❌ 再生エラー: $e");
    }
  }

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async => await _player.stop();

  /// ✅ 安全なリセット（例外防止）
  Future<void> reset() async {
    try {
      await _player.seek(Duration.zero);
    } catch (e) {
      print("❌ リセット中にエラー発生: $e");
    }
  }

  /// ✅ assets/audio/ 配下の音声ファイルを一時保存してパスを返す
  Future<String> copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load('assets/$assetPath');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split("/").last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  void dispose() {
    _player.dispose();
    _positionController.close();
  }
}
