import 'dart:math';
import 'package:flutter/material.dart';

class RecordedWavePainter extends CustomPainter {
  final List<double> amplitudes;
  final double maxAmplitude;
  final double progress;

  RecordedWavePainter({
    required this.amplitudes,
    required this.maxAmplitude,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || maxAmplitude <= 0 || maxAmplitude.isNaN) return;

    final Paint pastWavePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint redLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5;

    final Paint futureWavePaint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final int totalSamples = amplitudes.length;
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double progressIndex = clampedProgress * totalSamples;
    final double scrollOffset =
        ((progressIndex - (totalSamples / 2)) / totalSamples) * size.width;

    Path pastPath = Path();
    Path futurePath = Path();
    bool hasPastPathStarted = false;
    bool hasFuturePathStarted = false;

    // 🔧 振幅を適度にブーストし、自然なスケーリングへ
    double normalize(double amp) {
      final scaled = amp * 4;
      return log(scaled + 1) / log(2); // logスケーリング
    }

    // 🔧 移動平均で滑らかに（5点）
    List<double> smoothed = List.filled(amplitudes.length, 0);
    for (int i = 2; i < amplitudes.length - 2; i++) {
      smoothed[i] = (amplitudes[i - 2] +
              amplitudes[i - 1] +
              amplitudes[i] +
              amplitudes[i + 1] +
              amplitudes[i + 2]) /
          5;
    }
    smoothed[0] = amplitudes[0];
    smoothed[1] = amplitudes[1];
    smoothed[amplitudes.length - 2] = amplitudes[amplitudes.length - 2];
    smoothed[amplitudes.length - 1] = amplitudes.last;

    for (int i = 0; i < smoothed.length - 1; i++) {
      double x1 = centerX +
          ((i - smoothed.length / 2) / smoothed.length) * size.width -
          scrollOffset;
      double y1 = size.height -
          (normalize(smoothed[i]) * size.height * 0.9); // ← maxAmplitude 使用しない

      double x2 = centerX +
          (((i + 1) - smoothed.length / 2) / smoothed.length) * size.width -
          scrollOffset;
      double y2 =
          size.height - (normalize(smoothed[i + 1]) * size.height * 0.9);

      if (y1.isNaN || y1.isInfinite || y2.isNaN || y2.isInfinite) continue;

      if (x1 < centerX) {
        if (!hasPastPathStarted) {
          pastPath.moveTo(x1, y1);
          hasPastPathStarted = true;
        }
        pastPath.lineTo(x2, y2);
      } else {
        if (!hasFuturePathStarted) {
          futurePath.moveTo(x1, y1);
          hasFuturePathStarted = true;
        }
        futurePath.lineTo(x2, y2);
      }
    }

    canvas.drawPath(pastPath, pastWavePaint);
    canvas.drawPath(futurePath, futureWavePaint);

    // 中央ライン
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      redLinePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
