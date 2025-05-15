import 'dart:async';
import 'package:flutter/material.dart';
import '../painters/realtime_waveform_painter.dart';

class RealtimeWaveformWidget extends StatefulWidget {
  final Stream<double> amplitudeStream;
  final int maxSamples;
  final double height;

  const RealtimeWaveformWidget({
    super.key,
    required this.amplitudeStream,
    this.maxSamples = 50,
    this.height = 100.0,
  });

  @override
  State<RealtimeWaveformWidget> createState() => _RealtimeWaveformWidgetState();
}

class _RealtimeWaveformWidgetState extends State<RealtimeWaveformWidget> {
  late StreamSubscription<double> _subscription;
  final List<double> _amplitudes = [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.amplitudeStream.listen((amplitude) {
      setState(() {
        // 0.0〜1.0の範囲で制限（必要なら強調可）
        _amplitudes.add(amplitude.clamp(0.0, 1.0));
        if (_amplitudes.length > widget.maxSamples) {
          _amplitudes.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: RealtimeWaveformPainter(amplitudes: _amplitudes),
      ),
    );
  }
}
