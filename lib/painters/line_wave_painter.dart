import 'package:flutter/material.dart';
import 'dart:math';

class LineWavePainter extends CustomPainter {
  final List<double> amplitudes;
  final double maxAmplitude;
  final double progress; // 0.0〜1.0（再生位置）

  LineWavePainter({
    required this.amplitudes,
    required this.maxAmplitude,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || maxAmplitude <= 0 || maxAmplitude.isNaN) return;

    final Paint pastWavePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Paint futureWavePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint redLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    final double centerX = size.width / 2;
    final int totalSamples = amplitudes.length;

    // 🎯 スクロール位置を progress に比例させる（シンプルでズレにくい）
    final double scrollOffset = progress * size.width;
    debugPrint(
        '🖌 progress: ${progress.toStringAsFixed(3)} → scrollOffset: ${scrollOffset.toStringAsFixed(2)}');

    Path pastPath = Path();
    Path futurePath = Path();
    bool hasPastPathStarted = false;
    bool hasFuturePathStarted = false;

    double normalize(double amp) => max(amp, 0.05);

    for (int i = 0; i < totalSamples - 1; i++) {
      double x1 = (i / totalSamples) * size.width - scrollOffset + centerX;
      double x2 =
          ((i + 1) / totalSamples) * size.width - scrollOffset + centerX;

      double y1 = size.height -
          ((normalize(amplitudes[i]) / maxAmplitude) * size.height * 1.2);
      double y2 = size.height -
          ((normalize(amplitudes[i + 1]) / maxAmplitude) * size.height * 1.2);

      if (y1.isNaN || y2.isNaN || y1.isInfinite || y2.isInfinite) continue;

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

    // 🔴 中央赤ライン（現在の再生位置）
    canvas.drawPath(pastPath, pastWavePaint);
    canvas.drawPath(futurePath, futureWavePaint);
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      redLinePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
