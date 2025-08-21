import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Duration? _duration;
  Duration? get totalDuration => _duration;
  set totalDuration(Duration? value) => _duration = value;

  // ---- 互換ストリーム ----
  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  final BehaviorSubject<Duration> _durationSubject =
      BehaviorSubject.seeded(Duration.zero);
  Stream<Duration> get durationStream => _durationSubject.stream;

  final BehaviorSubject<bool> _isPlayingSubject = BehaviorSubject.seeded(false);
  Stream<bool> get isPlayingStream => _isPlayingSubject.stream;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;

  String? _currentFilePath;

  // ===== チューニング =====
  static const Duration _kTailExtraSingle =
      Duration(milliseconds: 300); // 単発の余韻
  static const Duration _kTailExtraAB = Duration(milliseconds: 300); // AB の余韻
  static const Duration _kMinLen = Duration(milliseconds: 120); // 極短対策
  static const Duration _kTinyWait = Duration(milliseconds: 10); // seek直後の微待ち

  // ===== AB ループ用（イベント駆動） =====
  bool _abLooping = false;
  Completer<void>? _abCancel; // 中断用（stopABLoopでcomplete）

  AudioPlayerService() {
    _durationSub = _player.durationStream.listen((duration) {
      _duration = duration;
      if (duration != null) _durationSubject.add(duration);
    });

    _positionSub = _player.positionStream.listen((position) {
      _positionController.add(position);
    });

    _playingSub = _player.playingStream.listen((isPlaying) {
      _isPlayingSubject.add(isPlaying);
    });
  }

  bool get isActuallyPlaying => _player.playing;

  // ========= ヘルパ =========
  Duration _clampToTotal(Duration d) {
    final dur = totalDuration;
    if (dur == null) return d;
    if (d > dur) return dur;
    if (d.isNegative) return Duration.zero;
    return d;
  }

  // ========= 単発：開始ピッタリ／終了+余韻 =========
  Future<void> playSegmentOnce({
    required Duration start,
    required Duration end,
    Duration? tailExtra, // 任意で上書き
  }) async {
    if (_currentFilePath == null) return;

    if (end - start <= _kMinLen) {
      end = start + _kMinLen;
    }
    final endPlus = _clampToTotal(end + (tailExtra ?? _kTailExtraSingle));

    await _player.setLoopMode(LoopMode.off);
    await _player.pause();

    await _player.setClip(start: start, end: endPlus);

    // クリップ内先頭(=0)から再生 → 開始ピッタリ
    await _player.seek(Duration.zero);
    await Future.delayed(_kTinyWait);
    await _player.play();

    // クリップ終端（実エンジンが判断）で completed
    await _player.processingStateStream
        .firstWhere((s) => s == ProcessingState.completed);

    // 後片付け
    await _player.pause();
    await _player.setClip(start: null, end: null);
    await _player.seek(endPlus);
  }

  // 互換別名
  Future<void> playSegmentWithTailOnce({
    required Duration start,
    required Duration end,
    Duration tailExtra = _kTailExtraSingle,
  }) =>
      playSegmentOnce(start: start, end: end, tailExtra: tailExtra);

  // ========= AB：completed 駆動で 1 周ずつ正確ループ =========
  Future<void> playABLoop({
    required Duration a,
    required Duration b,
    Duration? tailExtra, // 任意で上書き
  }) async {
    if (_currentFilePath == null) return;

    if (b - a <= _kMinLen) b = a + _kMinLen;

    // B+余韻を作成し、ファイル末尾ギリギリなら少し手前にクランプ
    final dur = totalDuration;
    var bPlus = _clampToTotal(b + (tailExtra ?? _kTailExtraAB));
    if (dur != null && bPlus >= dur - const Duration(milliseconds: 20)) {
      bPlus = dur - const Duration(milliseconds: 20);
    }
    if (bPlus <= a) bPlus = a + _kMinLen;

    // 旧ループを終了
    _abLooping = false;
    _abCancel?.complete();
    _abCancel = null;

    // 新ループ開始
    _abLooping = true;
    _abCancel = Completer<void>();

    // 非同期で回す（awaitしない）
    // ignore: unawaited_futures
    _runAbLoop(a, bPlus);
  }

  Future<void> _runAbLoop(Duration a, Duration bPlus) async {
    while (_abLooping) {
      try {
        await _player.setLoopMode(LoopMode.off);
        await _player.setClip(start: a, end: bPlus);

        // クリップ内先頭(=0)から開始 → Aにピッタリ
        await _player.seek(Duration.zero);
        await Future.delayed(_kTinyWait);
        await _player.play();

        // ① clip終端（completed） or ② 中断 のどちらか先で抜ける
        final completedF = _player.processingStateStream
            .firstWhere((s) => s == ProcessingState.completed);
        final cancelF = _abCancel!.future;

        await Future.any([completedF, cancelF]);
        if (!_abLooping) break;

        // 次周準備：後片付け＋Aへ
        await _player.pause();
        await _player.setClip(start: null, end: null);
        await _player.seek(a);
        // 次の while で再度 setClip→seek→play
      } catch (e) {
        debugPrint('AB loop error: $e');
        break;
      }
    }

    // ループ終了クリーンアップ
    await _player.setLoopMode(LoopMode.off);
    await _player.setClip(start: null, end: null);
  }

  Future<void> stopABLoop() async {
    _abLooping = false;
    _abCancel?.complete();
    _abCancel = null;

    await _player.setLoopMode(LoopMode.off);
    await _player.pause();
    await _player.setClip(start: null, end: null);
  }

  // ========= 基本操作 =========
  Future<void> seek(Duration position) async => _player.seek(position);

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
    // AB も止める
    _abLooping = false;
    _abCancel?.complete();
    _abCancel = null;

    await _player.stop();
    await _player.setClip(start: null, end: null);
    await _player.setLoopMode(LoopMode.off);
    debugPrint("⏹ 停止");
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    debugPrint("🚀 再生速度: ${speed}x");
  }

  Future<void> reset() async {
    try {
      // AB も止める
      _abLooping = false;
      _abCancel?.complete();
      _abCancel = null;

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

  // 互換API（他所で使っていれば）
  Future<void> setClipRange({Duration? start, Duration? end}) async {
    await _player.setClip(start: start, end: end);
  }

  Future<void> setLooping(bool enabled) async {
    await _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
  }

  // 位置ストリーム（直接）
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> dispose() async {
    try {
      _abLooping = false;
      _abCancel?.complete();
      _abCancel = null;

      await stop();
      await _player.dispose();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      await _playingSub?.cancel();
      await _positionController.close();
      await _durationSubject.close();
      await _isPlayingSubject.close();
    } catch (e) {
      debugPrint('⚠️ dispose エラー: $e');
    }
  }

  // ========== おまけ：アセット→一時ファイル ==========
  Future<String> copyAssetToFile(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split("/").last}');
    if (await file.exists()) {
      debugPrint("📁 既存のキャッシュファイルを使用: ${file.path}");
      return file.path;
    }
    final byteData = await rootBundle.load('assets/$assetPath');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    debugPrint("🆕 asset からファイルをコピー: ${file.path}");
    return file.path;
  }
}
