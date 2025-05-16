import 'package:flutter/material.dart';

class LineWavePainter extends CustomPainter {
  final List<double> amplitudes;
  final double maxAmplitude;
  final double progress;

  LineWavePainter({
    required this.amplitudes,
    required this.maxAmplitude,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || maxAmplitude <= 0 || maxAmplitude.isNaN) return;

    final Paint pastWavePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint redLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5;

    final Paint futureWavePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    double centerX = size.width / 2;
    double scrollOffset = progress * size.width;

    Path pastPath = Path();
    Path futurePath = Path();

    bool hasPastPathStarted = false;
    bool hasFuturePathStarted = false;

    for (int i = 0; i < amplitudes.length - 1; i++) {
      double x1 = centerX +
          ((i - amplitudes.length / 2) / amplitudes.length) * size.width -
          scrollOffset;
      double y1 = size.height / 2 -
          ((amplitudes[i] / maxAmplitude) * size.height * 0.6);
      double x2 = centerX +
          (((i + 1) - amplitudes.length / 2) / amplitudes.length) * size.width -
          scrollOffset;
      double y2 = size.height / 2 -
          ((amplitudes[i + 1] / maxAmplitude) * size.height * 0.6);

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

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      redLinePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
