// lib/widgets/realtime_waveform_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/mic_amplitude_service.dart';
import '../painters/line_wave_painter.dart';

class RealtimeWaveformWidget extends StatefulWidget {
  final MicAmplitudeService mic;
  final int displaySeconds; // 可視窓（秒）
  final double heightScale; // 縦スケール 0..1
  final Color waveColor;
  final bool showCenterLine;
  final bool showMovingDot;
  final double verticalPadding; // 下端の余白

  const RealtimeWaveformWidget({
    super.key,
    required this.mic,
    this.displaySeconds = 2,
    this.heightScale = 0.92,
    this.waveColor = Colors.blueAccent,
    this.showCenterLine = false,
    this.showMovingDot = true,
    this.verticalPadding = 10.0,
  });

  @override
  State<RealtimeWaveformWidget> createState() => _RealtimeWaveformWidgetState();
}

class _RealtimeWaveformWidgetState extends State<RealtimeWaveformWidget> {
  final List<double> _buf = []; // 0..1
  StreamSubscription<double>? _sub;
  Timer? _ticker; // 60fps リフレッシュ
  bool _dirty = false;

  int get _cap => widget.displaySeconds * 200; // 200fps

  @override
  void initState() {
    super.initState();
    _sub = widget.mic.amplitudeStream.listen((v) {
      _buf.add(v.clamp(0.0, 1.0));
      if (_buf.length > _cap) {
        _buf.removeRange(0, _buf.length - _cap);
      }
      _dirty = true;
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      if (_dirty) {
        _dirty = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_buf.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: LineWavePainter(
        amplitudes: _buf,
        progress: 1.0, // 右端が現在
        samplesPerSecond: 200,
        displaySeconds: widget.displaySeconds,
        waveColor: widget.waveColor,
        showCenterLine: widget.showCenterLine,
        showMovingDot: widget.showMovingDot,
        heightScale: widget.heightScale,
        maxAmplitude: 1.0, // 使っていないが必須パラなら 1.0
        verticalPadding: widget.verticalPadding,
      ),
    );
  }
}
