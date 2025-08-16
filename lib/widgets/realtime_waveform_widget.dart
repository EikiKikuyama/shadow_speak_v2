// lib/widgets/realtime_waveform_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart'; // ← ここが見本波形と共通！

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
        // 🎯 平均化して波形をなめらかに
        final avg = _bufferedAmplitudes.reduce((a, b) => a + b) /
            _bufferedAmplitudes.length;

        setState(() {
          _amplitudes.add(avg);
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
      painter: LineWavePainter(
        amplitudes: _amplitudes,
        progress: 1.0, // 常に全体表示
      ),
    );
  }
}
