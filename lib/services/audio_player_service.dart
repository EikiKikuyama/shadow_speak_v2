import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Duration? _duration;
  // ignore: unnecessary_getters_setters
  Duration? get totalDuration => _duration;
  set totalDuration(Duration? value) => _duration = value;

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

  /// アセットの通常再生
  Future<void> play(String sourcePath) async {
    await _player.stop();
    await _player.setAsset(sourcePath);
    await _player.play();
  }

  /// 再開機能付きスマート再生（途中から or 初めから）
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

  /// 🆕 再開メソッド（停止後の再生位置から再開）
  Future<void> resume() async {
    if (_currentFilePath == null) {
      debugPrint("❌ resume: ファイルパスが未設定");
      return;
    }
    try {
      if (_player.playerState.processingState == ProcessingState.ready) {
        await _player.play();
        debugPrint("▶️ resume: 再開しました");
      } else {
        debugPrint("⚠️ resume: 再生準備ができていません");
      }
    } catch (e) {
      debugPrint("❌ resume エラー: $e");
    }
  }

  /// ローカルファイルの準備＋再生
  Future<void> prepareAndPlayLocalFile(String filePath, double speed) async {
    await setSpeed(speed);
    await stop(); // ソース切り替えのため
    await Future.delayed(const Duration(milliseconds: 200));
    await _player.setFilePath(filePath);
    _currentFilePath = filePath;
    totalDuration = _player.duration;
    await _player.play();
    debugPrint("▶️ prepareAndPlay: 再生開始");
  }

  /// 再生準備のみ（波形用）
  Future<void> prepareLocalFile(String path, double speed) async {
    await setSpeed(speed);
    await _player.setFilePath(path);
    _currentFilePath = path;
    totalDuration = _player.duration;
    debugPrint("📦 prepareLocalFile: duration = $totalDuration");
  }

  Future<void> pause() async {
    await _player.pause();
    debugPrint("⏸ 一時停止");
  }

  Future<void> stop() async {
    await _player.stop();
    // _currentFilePath は残すことで resume が可能になる
    debugPrint("⏹ 停止");
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
