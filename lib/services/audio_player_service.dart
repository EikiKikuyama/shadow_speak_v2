import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
// ignore: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Duration? _duration;
  Duration? get totalDuration => _duration;
  set totalDuration(Duration? value) => _duration = value;

  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  final BehaviorSubject<Duration> _durationSubject =
      BehaviorSubject.seeded(Duration.zero);
  Stream<Duration> get durationStream => _durationSubject.stream;

  final BehaviorSubject<bool> _isPlayingSubject = BehaviorSubject.seeded(false);
  Stream<bool> get isPlayingStream => _isPlayingSubject.stream;

  String? _currentFilePath;

  AudioPlayerService() {
    _player.durationStream.listen((duration) {
      _duration = duration;
      if (duration != null) {
        _durationSubject.add(duration);
      }
    });

    _player.positionStream.listen((position) {
      _positionController.add(position);
    });

    _player.playingStream.listen((isPlaying) {
      _isPlayingSubject.add(isPlaying);
    });
  }

  bool get isActuallyPlaying => _player.playing;

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> resume() async {
    if (_currentFilePath == null) {
      debugPrint("❌ resume: ファイルパスが未設定");
      return;
    }
    try {
      if (_player.playerState.processingState == ProcessingState.ready ||
          _player.playerState.processingState == ProcessingState.completed) {
        await _player.play();
        debugPrint("▶️ resume: 再開しました");
      } else {
        debugPrint("⚠️ resume: 再生準備ができていません");
      }
    } catch (e) {
      debugPrint("❌ resume エラー: $e");
    }
  }

  Future<void> prepareAndPlayLocalFile(String filePath, double speed) async {
    await setSpeed(speed);
    await stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _player.setFilePath(filePath);
    _currentFilePath = filePath;
    totalDuration = _player.duration;
    await _player.play();
    debugPrint("▶️ prepareAndPlay: 再生開始");
    debugPrint("🕒 再生ファイル duration: ${_player.duration}");
  }

  Future<void> prepareLocalFile(String path, double speed) async {
    await setSpeed(speed);
    await _player.setFilePath(path);
    _currentFilePath = path;
    totalDuration = _player.duration;
    debugPrint("📦 prepareLocalFile: duration = $totalDuration");
  }

  Future<Duration?> getDuration(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      return _player.duration;
    } catch (e) {
      debugPrint("❌ getDuration エラー: $e");
      return null;
    }
  }

  Future<void> pause() async {
    await _player.pause();
    debugPrint("⏸ 一時停止");
  }

  Future<void> stop() async {
    await _player.stop();
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

  Stream<Duration> get positionStream => _player.positionStream;

  void dispose() {
    _player.dispose();
    _positionController.close();
    _durationSubject.close();
    _isPlayingSubject.close();
  }
}
