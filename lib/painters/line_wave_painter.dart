import 'package:flutter/material.dart';
import 'dart:math';

class LineWavePainter extends CustomPainter {
  final List<double> amplitudes;
  final double maxAmplitude;
  final double progress; // 0.0〜1.0 再生位置
  final int samplesPerSecond;
  final int displaySeconds;

  LineWavePainter({
    required this.amplitudes,
    required this.maxAmplitude,
    required this.progress,
    this.samplesPerSecond = 100,
    this.displaySeconds = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || maxAmplitude <= 0 || maxAmplitude.isNaN) return;

    final int totalSamples = amplitudes.length;
    final int displaySamples = samplesPerSecond * displaySeconds;

    final double unitWidth = size.width / displaySamples;

    int centerSampleIndex = (progress * totalSamples).round();

    int startIndex = max(0, centerSampleIndex - (displaySamples ~/ 2));
    int endIndex = min(totalSamples, startIndex + displaySamples);

    double offsetX = 0;

    final double centerX = size.width / 2;
    final double progressX =
        (centerSampleIndex - startIndex) * unitWidth + offsetX;

    Path path = Path();

    double normalize(double amp) => max(amp, 0.05);

    // 波形線を描く
    for (int i = startIndex; i < endIndex; i++) {
      double x = (i - startIndex) * unitWidth + offsetX;
      double normAmp = normalize(amplitudes[i]) / maxAmplitude;
      double y = size.height - (normAmp * size.height * 1.2);

      if (i == startIndex) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 線の描画
    final Paint wavePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, wavePaint);

    // 再生中のポイント（丸）を大きく表示
    if (centerSampleIndex >= startIndex && centerSampleIndex < endIndex) {
      double x = (centerSampleIndex - startIndex) * unitWidth + offsetX;
      double normAmp = normalize(amplitudes[centerSampleIndex]) / maxAmplitude;
      double y = size.height - (normAmp * size.height * 1.2);

      final Paint highlightPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, highlightPaint);
    }

    // 赤い再生位置ライン（中央固定）
    final Paint redLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      redLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
