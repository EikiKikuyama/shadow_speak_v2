import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:intl/intl.dart';
// ← FileやDirectoryを使っている場合

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;
  String? recordedFilePath;
  bool isRecording = false;
  StreamSubscription<RecordState>? _stateSubscription;

  double _maxObservedAmplitude = 0.0;

  String? get getRecordedFilePath => recordedFilePath;

  // 🔊 振幅ストリーム（0〜1に正規化）
  Stream<double> get amplitudeStream => _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .map((event) {
        double amplitude = event.current;
        double normalized = (amplitude + 160) / 160;
        double boosted = (normalized - 0.6) * 10;
        final value = boosted.clamp(0.0, 1.0);

        if (value > _maxObservedAmplitude) {
          _maxObservedAmplitude = value;
          dev.log('📈 最大振幅更新: $_maxObservedAmplitude');
        }

        dev.log('🎤 Raw: $amplitude, Normalized: $normalized, Boosted: $value');
        return value;
      });

  // 🎙️ 録音開始
  Future<void> startRecording({
    required String level,
    required String title,
    String? path,
  }) async {
    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) throw Exception("録音の許可がありません");

      final savePath =
          path ?? await getSavePath(level: level, title: title); // ← 自動生成
      _filePath = savePath;

      await _recorder.start(
        RecordConfig(encoder: AudioEncoder.wav),
        path: _filePath!,
      );

      isRecording = true;
      recordedFilePath = null;
      _maxObservedAmplitude = 0.0;

      _stateSubscription?.cancel();
      _stateSubscription = _recorder.onStateChanged().listen((state) {
        if (state == RecordState.record) {
          dev.log("🎤 録音中...");
        }
      });
    } catch (e) {
      dev.log("❌ 録音開始エラー: $e");
    }
  }

  // 🛑 録音停止
  Future<String?> stopRecording() async {
    try {
      String? filePath = await _recorder.stop();
      dev.log("🎤 録音停止: $filePath");

      isRecording = false;
      if (filePath != null) {
        recordedFilePath = filePath;

        final size = await File(filePath).length();
        dev.log("📦 録音ファイルサイズ: $size bytes");
      }

      dev.log("✅ この録音の最大振幅: $_maxObservedAmplitude");

      await _stateSubscription?.cancel();
      _stateSubscription = null;

      return filePath;
    } catch (e) {
      dev.log("❌ 録音停止エラー: $e");
      return null;
    }
  }

  // 📁 パス生成
  // 📁 パス生成（安全なファイル名）
  Future<String> getSavePath({
    required String level,
    required String title,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingDir = Directory('${dir.path}/shadow_speak/recordings');

    if (!await recordingDir.exists()) {
      await recordingDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    // スペース → ハイフン に変換してセパレータを __ に統一
    final safeLevel = level.replaceAll(' ', '-');
    final safeTitle = title.replaceAll(' ', '-');

    return '${recordingDir.path}/$safeLevel\_\_${safeTitle}\_\_${timestamp}.wav';
  }

  // 📊 波形抽出
  Future<List<double>> extractWaveform(
      File file, Duration audioDuration) async {
    final List<double> waveform = [];
    try {
      final Uint8List data = await file.readAsBytes();
      int totalSamples = data.length ~/ 2;

      if (audioDuration.inSeconds == 0) {
        dev.log("⚠️ audioDurationが0秒のため波形抽出をスキップします。");
        return [];
      }

      int desiredSamples = audioDuration.inSeconds * 100;
      int groupSize = (totalSamples / desiredSamples).ceil();

      final ByteData byteData = ByteData.sublistView(data);

      for (int i = 0; i < totalSamples; i += groupSize) {
        int end = (i + groupSize).clamp(0, totalSamples);
        double sum = 0.0;
        int count = 0;

        for (int j = i; j < end; j++) {
          int sample = byteData.getInt16(j * 2, Endian.little);
          double normalized = sample.abs() / 327.68;
          sum += normalized;
          count++;
        }

        waveform.add(count > 0 ? sum / count : 0.0);
      }

      if (waveform.isEmpty) {
        dev.log("⚠️ waveformが空です。抽出に失敗した可能性があります。");
      } else {
        dev.log(
            "🔍 waveformの最初の20個: ${waveform.take(20).map((v) => v.toStringAsFixed(2)).toList()}");
        dev.log("📏 waveformの最大値: ${waveform.reduce(max).toStringAsFixed(2)}");
        dev.log("📊 waveformの長さ: ${waveform.length}");
      }
    } catch (e) {
      dev.log("⚠️ 波形抽出失敗: $e");
    }

    return waveform;
  }

  Future<void> stop() async {
    await stopRecording();
  }

  void dispose() {
    _stateSubscription?.cancel();
  }
}
