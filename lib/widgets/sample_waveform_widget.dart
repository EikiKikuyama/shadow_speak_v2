import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/waveform_extractor.dart';
import '../painters/line_wave_painter.dart'; // ← まだ作ってなければ今は仮

class SampleWaveformWidget extends StatelessWidget {
  final String filePath;
  final double height;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadAndProcessWaveform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final waveform = snapshot.data!;
        final maxAmplitude =
            waveform.reduce((a, b) => a > b ? a : b) * 1.5; // 拡大して見やすく

        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: LineWavePainter(
              amplitudes: waveform,
              maxAmplitude: maxAmplitude,
              progress: 0.0, // ← 再生位置がないので0固定
            ),
          ),
        );
      },
    );
  }

  Future<List<double>> _loadAndProcessWaveform() async {
    final file = File(filePath);
    final raw = extractWaveform(file);
    final processed = processWaveform(raw);
    return processed;
  }
}
