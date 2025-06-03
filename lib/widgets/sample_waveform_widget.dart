import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../services/audio_player_service.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatelessWidget {
  final String filePath;
  final bool isAsset;
  final AudioPlayerService audioPlayerService;
  final double playbackSpeed;
  final double height;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.audioPlayerService,
    required this.playbackSpeed,
    this.height = 200,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadAndProcessWaveform(),
      builder: (context, snapshot) {
        final waveform = snapshot.data;

        // ⚠️ waveform が null または空なら描画スキップ
        if (waveform == null || waveform.isEmpty) {
          debugPrint("⚠️ waveformがnullまたは空です。描画スキップ（$filePath）");
          return const SizedBox();
        }

        final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.2;

        return StreamBuilder<Duration>(
          stream: audioPlayerService.onPositionChanged,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final originalDuration = audioPlayerService.totalDuration ??
                Duration(seconds: 3); // 仮duration

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
    debugPrint(
        "🧪 SampleWaveformWidget: filePath = $filePath, isAsset = $isAsset");

    List<double> raw;
    try {
      if (isAsset) {
        raw = await extractWaveformFromAssets(filePath);
      } else {
        raw = extractWaveform(File(filePath));
      }
    } catch (e) {
      debugPrint("❌ 波形抽出エラー: $e");
      raw = [];
    }

    if (raw.isEmpty) {
      debugPrint("⚠️ 抽出された波形が空です（$filePath）");
    }

    return processWaveform(raw);
  }
}
