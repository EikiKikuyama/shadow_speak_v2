import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Duration? _duration;
  Duration? get totalDuration => _duration;

  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  String? _currentFilePath; // ✅ 現在の再生ファイルを保持（再設定防止）

  AudioPlayerService() {
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
    });

    _player.onPositionChanged.listen((position) {
      _positionController.add(position);
    });
  }

  /// ✅ アセット音声再生（Listeningモード等）
  Future<void> play(String sourcePath) async {
    await _player.stop(); // アセット再生は常にリセットでOK
    await _player.play(AssetSource(sourcePath));
  }

  /// ✅ ローカルファイル再生（途中からresume可能）
  Future<void> playLocalFile(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      debugPrint("❌ ファイルが存在しません: $filePath");
      return;
    }

    try {
      // 同じファイルならソースを再設定しない
      if (_currentFilePath != filePath) {
        await _player.setSource(DeviceFileSource(filePath));
        _currentFilePath = filePath;
        debugPrint("🎧 ソース設定: $filePath");
      } else {
        debugPrint("🔁 ソース再設定スキップ: $filePath");
      }

      await _player.resume();
      debugPrint("▶️ 再生開始: $filePath");
    } catch (e) {
      debugPrint("❌ 再生エラー: $e");
    }
  }

  /// ⏸ 一時停止（再開可能）
  Future<void> pause() async {
    await _player.pause();
    debugPrint("⏸ 一時停止");
  }

  /// ⏹ 完全停止（再開不可、ソース保持も解除）
  Future<void> stop() async {
    await _player.stop();
    _currentFilePath = null;
    debugPrint("⏹ 停止＆ソース解除");
  }

  Future<void> smartPlayLocalFile(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      debugPrint("❌ smartPlay: ファイルが存在しません: $filePath");
      return;
    }

    try {
      final state = _player.state;

      if (state == PlayerState.paused && _currentFilePath == filePath) {
        // ✅ 一時停止中で同じファイル → resume
        await _player.resume();
        debugPrint("▶️ smartPlay: 再開");
      } else {
        // ✅ 別ファイル or 初回再生 → ソース設定して再生
        await _player.setSource(DeviceFileSource(filePath));
        _currentFilePath = filePath;
        await _player.resume();
        debugPrint("🎧 smartPlay: ソース設定して再生");
      }
    } catch (e) {
      debugPrint("❌ smartPlay エラー: $e");
    }
  }

  /// 🔄 再生位置を先頭に戻す（再生中または一時停止中の場合のみ）
  Future<void> reset() async {
    try {
      final state = _player.state;
      if (state == PlayerState.playing || state == PlayerState.paused) {
        await _player.seek(Duration.zero);
        debugPrint("🔄 リセット：先頭に戻しました");
      } else {
        debugPrint("⚠️ リセットスキップ：ソースが未設定または停止中");
      }
    } catch (e) {
      debugPrint("❌ リセットエラー: $e");
    }
  }

  /// ✅ アセットファイルを一時ファイルにコピーして使用（.wavなど）
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
