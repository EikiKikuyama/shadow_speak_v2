import 'dart:async';
import 'package:flutter/material.dart';

class RealtimeWaveformWidget extends StatefulWidget {
  final Stream<double> amplitudeStream;
  final double height;

  const RealtimeWaveformWidget({
    super.key,
    required this.amplitudeStream,
    required this.height,
  });

  @override
  State<RealtimeWaveformWidget> createState() => _RealtimeWaveformWidgetState();
}

class _RealtimeWaveformWidgetState extends State<RealtimeWaveformWidget> {
  final List<double> _amplitudes = [];
  late StreamSubscription<double> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.amplitudeStream.listen(
      (amplitude) {
        // 波形更新ロジック
      },
      onError: (e) {
        debugPrint("❌ Streamエラー: $e");
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: _WaveformPainter(_amplitudes),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;

  _WaveformPainter(this.amplitudes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final centerY = size.height / 2;
    final widthPerSample = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length - 1; i++) {
      final x1 = i * widthPerSample;
      final y1 = centerY - (amplitudes[i] * centerY).clamp(-centerY, centerY);
      final x2 = (i + 1) * widthPerSample;
      final y2 =
          centerY - (amplitudes[i + 1] * centerY).clamp(-centerY, centerY);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
