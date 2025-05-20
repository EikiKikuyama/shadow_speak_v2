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
  final List<double> _bufferedAmplitudes = [];
  late StreamSubscription<double> _subscription;
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();

    _subscription = widget.amplitudeStream.listen(
      (amplitude) {
        _bufferedAmplitudes.add(amplitude);
      },
      onError: (e) {
        debugPrint("❌ Streamエラー: $e");
      },
    );

    _throttleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_bufferedAmplitudes.isNotEmpty) {
        setState(() {
          _amplitudes.addAll(_bufferedAmplitudes);
          _bufferedAmplitudes.clear();
          if (_amplitudes.length > 100) {
            _amplitudes.removeRange(0, _amplitudes.length - 100);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _throttleTimer?.cancel();
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

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final widthPerSample = amplitudes.isNotEmpty
        ? size.width / 100 // 固定幅を想定
        : size.width;

    final int sampleCount = amplitudes.length;

    for (int i = 0; i < sampleCount - 1; i++) {
      // 最新データを centerX に合わせる
      final x1 = centerX - (sampleCount - 1 - i) * widthPerSample;
      final x2 = centerX - (sampleCount - 2 - i) * widthPerSample;

      final y1 =
          centerY - (amplitudes[i] * centerY * 10).clamp(-centerY, centerY);
      final y2 =
          centerY - (amplitudes[i + 1] * centerY * 10).clamp(-centerY, centerY);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}
