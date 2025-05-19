import 'package:flutter/material.dart';

class RealtimeWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double height;

  RealtimeWaveformPainter({
    required this.amplitudes,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double widthPerSample = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length - 1; i++) {
      final double x1 = centerX - (amplitudes.length - i) * widthPerSample;
      final double x2 = centerX - (amplitudes.length - i - 1) * widthPerSample;

      final double y1 =
          centerY - (amplitudes[i] * centerY).clamp(-centerY, centerY);
      final double y2 =
          centerY - (amplitudes[i + 1] * centerY).clamp(-centerY, centerY);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
