import 'package:flutter/material.dart';

class RealtimeWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  RealtimeWaveformPainter({
    required this.amplitudes,
    this.color = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final height = size.height;

    // 最新が最後に追加されると仮定（右から左へ描画）
    for (int i = 0; i < amplitudes.length; i++) {
      final x = centerX - i * 4; // 4px間隔で左に描画
      if (x < 0) break;

      final amplitude = amplitudes[amplitudes.length - 1 - i];
      final barHeight = amplitude * height;

      canvas.drawLine(
        Offset(x, height / 2 - barHeight / 2),
        Offset(x, height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RealtimeWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}
