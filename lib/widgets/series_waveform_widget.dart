import 'package:flutter/widgets.dart';
import '../painters/line_wave_painter.dart'; // 既存のPainterを使う想定

class SeriesWaveformWidget extends StatelessWidget {
  final List<double> series; // 0..1 正規化済み
  final double progress; // 0..1 再生位置
  final double verticalPadding; // ★追加

  const SeriesWaveformWidget({
    super.key,
    required this.series,
    required this.progress,
    this.verticalPadding = 10.0, // 推奨 8–12px
  });

  @override
  Widget build(BuildContext context) {
    // 親コンテナ（buildWaveformContainer）が高さ/幅を決めるので、expandでフィット
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: LineWavePainter(
            amplitudes: series,
            maxAmplitude: 1.0,
            progress: progress,
            verticalPadding: verticalPadding, // ★ 渡す
          ),
        ),
      ),
    );
  }
}
