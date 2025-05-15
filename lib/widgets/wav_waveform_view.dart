import 'package:flutter/material.dart';

class WavWaveformView extends StatelessWidget {
  final List<double> amplitudes;

  const WavWaveformView({super.key, required this.amplitudes});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _WaveformPainter(amplitudes),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;

  _WaveformPainter(this.amplitudes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0;

    final middle = size.height / 2;
    final widthPerSample = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * widthPerSample;
      final y = amplitudes[i] * (size.height / 2);
      canvas.drawLine(Offset(x, middle - y), Offset(x, middle + y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
