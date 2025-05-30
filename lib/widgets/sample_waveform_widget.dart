import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../services/audio_player_service.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatelessWidget {
  final String filePath;
  final bool isAsset; // ← 新規追加ポイント
  final AudioPlayerService audioPlayerService;
  final double playbackSpeed; // UI互換用に残す
  final double height;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.audioPlayerService,
    required this.playbackSpeed,
    this.height = 200,
    this.isAsset = false, // ← デフォルトはfalse（録音ファイル）
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadAndProcessWaveform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final waveform = snapshot.data!;
        final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.2;

        return StreamBuilder<Duration>(
          stream: audioPlayerService.onPositionChanged,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final originalDuration = audioPlayerService.totalDuration;

            if (originalDuration == null ||
                originalDuration.inMilliseconds <= 0) {
              debugPrint("⚠️ duration 未取得: 波形描画スキップ");
              return const SizedBox();
            }

            double progress =
                position.inMilliseconds / originalDuration.inMilliseconds;
            progress = progress.clamp(0.0, 1.0);

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
    List<double> raw;
    if (isAsset) {
      raw = await extractWaveformFromAssets(filePath);
    } else {
      raw = extractWaveform(File(filePath));
    }
    return processWaveform(raw);
  }
}
