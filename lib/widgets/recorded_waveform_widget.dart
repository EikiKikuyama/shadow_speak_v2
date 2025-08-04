import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';
import 'dart:math';

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
        final waveform = snapshot.data;

        if (waveform == null || waveform.isEmpty) {
          debugPrint("⚠️ [Recorded] waveformがnullまたは空です。描画スキップ（$filePath）");
          return const SizedBox();
        }

        final maxAmplitude =
            waveform.any((e) => e > 0) ? waveform.reduce(max).abs() * 1.2 : 1.0;

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
    final raw = await extractWaveform(File(filePath)); // ✅ awaitを追加
    return processWaveform(raw,
        audioDuration.inMilliseconds / 1000.0); // これで raw は List<double> になってOK
  }
}
