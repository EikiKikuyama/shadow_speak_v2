import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatefulWidget {
  final String filePath;
  final double height;
  final double progress; // 0..1
  final bool isAsset;
  final int samplesPerSecond; // 200
  final int displaySeconds; // ★ 親から必ず渡す

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.height,
    required this.progress,
    this.isAsset = false,
    this.samplesPerSecond = 200,
    this.displaySeconds = 3, // ★ ここを required → 既定値(=2) に変更
  });

  @override
  State<SampleWaveformWidget> createState() => _SampleWaveformWidgetState();
}

class _SampleWaveformWidgetState extends State<SampleWaveformWidget> {
  Future<List<double>>? _waveF;

  @override
  void initState() {
    super.initState();
    _waveF = _load();
  }

  Future<List<double>> _load() async {
    final pcm = widget.isAsset
        ? await decodeWaveFromAssets(widget.filePath)
        : await decodeWaveFromFile(File(widget.filePath));
    return processWaveformUniform(pcm); // 0..1 / 5ms刻み
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
              amplitudes: wf,
              progress: widget.progress,
              samplesPerSecond: widget.samplesPerSecond,
              displaySeconds: widget.displaySeconds, // ★ 渡す
              showCenterLine: false,
              showMovingDot: true,
              heightScale: 0.95,
              waveColor: Colors.blueAccent,
            ),
          ),
        );
      },
    );
  }
}
