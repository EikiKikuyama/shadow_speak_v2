import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../services/audio_player_service.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatelessWidget {
  final String filePath;
  final AudioPlayerService audioPlayerService;
  final double height;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.audioPlayerService,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadAndProcessWaveform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final waveform = snapshot.data!;
        final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.5;

        return StreamBuilder<Duration>(
          stream: audioPlayerService.onPositionChanged,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            // ✅ durationがnullの場合の保険（ms = 1 にしてゼロ割防止）
            final duration =
                audioPlayerService.totalDuration ?? Duration(milliseconds: 1);

            // ✅ 進行度（0.0〜1.0）を安全に計算
            double progress = position.inMilliseconds / duration.inMilliseconds;
            progress = progress.clamp(0.0, 1.0);

            // ✅ ログ表示（開発用）
            debugPrint("🟢 再生位置: $position");
            debugPrint("📏 総再生時間: $duration");
            debugPrint("➡️ 進行度: $progress");

            return SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: LineWavePainter(
                  amplitudes: waveform,
                  maxAmplitude: maxAmplitude,
                  progress: progress,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<double>> _loadAndProcessWaveform() async {
    final file = File(filePath);
    final raw = extractWaveform(file);
    return processWaveform(raw);
  }
}
