import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Duration? _duration;
  Duration? get totalDuration => _duration;

  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  String? _currentFilePath;

  AudioPlayerService() {
    _player.durationStream.listen((duration) {
      _duration = duration;
    });

    _player.positionStream.listen((position) {
      _positionController.add(position);
    });
  }

  /// 通常再生（アセット）
  Future<void> play(String sourcePath) async {
    await _player.stop();
    await _player.setAsset(sourcePath);
    await _player.play();
  }

  /// ⏯ スマート再生（resume or 再設定）
  Future<void> smartPlayLocalFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint("❌ smartPlay: ファイルが存在しません: $filePath");
      return;
    }

    try {
      final state = _player.playerState;

      if (state.playing == false &&
          _currentFilePath == filePath &&
          state.processingState == ProcessingState.ready) {
        await _player.play();
        debugPrint("▶️ smartPlay: 再開");
      } else {
        await _player.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await _player.setFilePath(filePath);
        _currentFilePath = filePath;
        await _player.play();
        debugPrint("🎧 smartPlay: ソース設定して再生");
      }
    } catch (e) {
      debugPrint("❌ smartPlay エラー: $e");
    }
  }

  /// 🆕 再生速度をセットして安全に再生開始
  Future<void> prepareAndPlayLocalFile(String filePath, double speed) async {
    await setSpeed(speed);
    await stop();
    await Future.delayed(const Duration(milliseconds: 200)); // wait for safety
    await _player.setFilePath(filePath);
    _currentFilePath = filePath;
    await _player.play();
    debugPrint("▶️ prepareAndPlay: 再生開始");
  }

  Future<void> pause() async {
    await _player.pause();
    debugPrint("⏸ 一時停止");
  }

  Future<void> stop() async {
    await _player.stop();
    _currentFilePath = null;
    debugPrint("⏹ 停止＆ソース解除");
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    debugPrint("🚀 再生速度: ${speed}x");
  }

  Future<void> reset() async {
    try {
      if (_player.playing ||
          _player.playerState.processingState == ProcessingState.ready) {
        await _player.seek(Duration.zero);
        debugPrint("🔄 リセット：先頭に戻しました");
      } else {
        debugPrint("⚠️ リセットスキップ：ソースが未設定または停止中");
      }
    } catch (e) {
      debugPrint("❌ リセットエラー: $e");
    }
  }

  Future<String> copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load('assets/$assetPath');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split("/").last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;

  void dispose() {
    _player.dispose();
    _positionController.close();
  }
}
