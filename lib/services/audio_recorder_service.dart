import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  String? _filePath;
  String? recordedFilePath;
  bool isRecording = false;
  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  Stream<double> get amplitudeStream =>
      _amplitudeController.stream.asBroadcastStream();

  Future<void> startRecording() async {
    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) throw Exception("録音の許可がありません");

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory("${directory.path}/recordings");
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }
      _filePath =
          "${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _recorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc),
        path: _filePath!,
      );

      isRecording = true;
      recordedFilePath = null;

      _stateSubscription?.cancel();
      _stateSubscription = _recorder.onStateChanged().listen((state) {
        if (state == RecordState.record) {
          log("🎤 録音中...");
        }
      });

      _amplitudeSubscription ??= _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((event) {
        double amplitude = event.current;
        double normalized = (amplitude + 160) / 160;
        double boosted = (normalized - 0.8) * 10;
        boosted = boosted.clamp(0.0, 1.0);

        log("📊 raw: $amplitude, norm: $normalized, boosted: $boosted");

        // ✅ ここが抜けてた！
        _amplitudeController.add(boosted);
      }, onError: (e) {
        log("❌ 振幅エラー: $e");
      });
    } catch (e) {
      log("❌ 録音開始エラー: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      String? filePath = await _recorder.stop();
      log("🎤 録音停止: $filePath");

      isRecording = false;
      if (filePath != null) recordedFilePath = filePath;

      await _stateSubscription?.cancel();
      _stateSubscription = null;

      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      return filePath;
    } catch (e) {
      log("❌ 録音停止エラー: $e");
      return null;
    }
  }

  Future<List<double>> extractWaveform(
      File file, Duration audioDuration) async {
    final List<double> waveform = [];
    try {
      final Uint8List data = await file.readAsBytes();
      int totalSamples = data.length ~/ 2;
      int desiredSamples = audioDuration.inSeconds * 10;
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
    } catch (e) {
      log("⚠️ 波形抽出失敗: $e");
    }

    return waveform;
  }

  void dispose() {
    _stateSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
  }
}
