import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';

class RecordedWaveformWidget extends StatelessWidget {
  final String filePath;
  final Duration audioDuration;
  final double height;
  final double progress;
  final bool isAsset;

  const RecordedWaveformWidget({
    super.key,
    required this.filePath,
    required this.audioDuration,
    required this.height,
    required this.progress,
    this.isAsset = false,
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
        final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.2;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: LineWavePainter(
              amplitudes: waveform,
              maxAmplitude: maxAmplitude,
              progress: progress,
            ),
          ),
        );
      },
    );
  }

  Future<List<double>> _loadAndProcessWaveform() async {
    final raw = extractWaveform(File(filePath));
    return processWaveform(raw);
  }
}
