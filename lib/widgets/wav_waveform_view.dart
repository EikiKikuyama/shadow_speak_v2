import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';

class RecordedWaveformWidget extends StatefulWidget {
  final String filePath; // 録音WAVのパス
  final double height;
  final double progress; // 0.0〜1.0（親でpositionStreamから算出）
  final bool isAsset;
  final int samplesPerSecond; // 200 = 5ms刻み
  final int displaySeconds; // 可視窓（秒）
  final Color waveColor;

  const RecordedWaveformWidget({
    super.key,
    required this.filePath,
    required this.height,
    required this.progress,
    this.isAsset = false,
    this.samplesPerSecond = 200,
    this.displaySeconds = 4,
    this.waveColor = Colors.blueAccent,
  });

  @override
  State<RecordedWaveformWidget> createState() => _RecordedWaveformWidgetState();
}

class _RecordedWaveformWidgetState extends State<RecordedWaveformWidget> {
  late Future<List<double>> _waveF;

  @override
  void initState() {
    super.initState();
    _waveF = _loadWaveform(); // 一度だけ読み込んでキャッシュ
  }

  Future<List<double>> _loadWaveform() async {
    try {
      final pcm = widget.isAsset
          ? await decodeWaveFromAssets(widget.filePath)
          : await decodeWaveFromFile(File(widget.filePath));
      return processWaveformUniform(pcm); // 0..1 / 5ms刻み
    } catch (e) {
      debugPrint("❌ [Recorded] 波形読み込み失敗: $e");
      return const <double>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _waveF,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final wf = snap.data ?? const <double>[];
        if (wf.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: LineWavePainter(
              maxAmplitude: 1.0,
              amplitudes: wf, // 0..1
              progress: widget.progress, // 0..1
              samplesPerSecond: widget.samplesPerSecond, // 200
              displaySeconds: widget.displaySeconds, // 4
              waveColor: widget.waveColor,
            ),
          ),
        );
      },
    );
  }
}
