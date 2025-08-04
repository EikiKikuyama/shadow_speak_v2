import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatefulWidget {
  final String filePath;
  final double height;
  final double progress; // 0.0〜1.0
  final bool isAsset;
  final bool showComparison;
  final String? comparisonAssetPath;
  final int sampleRate;
  final int displaySeconds;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.height,
    required this.progress,
    this.isAsset = false,
    this.showComparison = false,
    this.comparisonAssetPath,
    this.sampleRate = 112, // 👈 ここを追加
    this.displaySeconds = 4, // 👈 ここも追加
  });

  @override
  State<SampleWaveformWidget> createState() => _SampleWaveformWidgetState();
}

class _SampleWaveformWidgetState extends State<SampleWaveformWidget> {
  late Future<List<double>> _waveformFuture;
  Duration? _audioDuration;

  @override
  void initState() {
    super.initState();
    _loadAndPrepare();
  }

  Future<void> _loadAndPrepare() async {
    try {} finally {
      final player = AudioPlayer();
      await player.setFilePath(widget.filePath);
      final duration = player.duration ?? Duration.zero;
      await player.dispose();

      List<double> raw = widget.isAsset
          ? await extractWaveformFromAssets(widget.filePath)
          : await extractWaveform(File(widget.filePath)); // ✅ ここに await を追加

      if (raw.isEmpty) {
        debugPrint("⚠️ 波形が空です（${widget.filePath}）");
      }

      // 正規化＋間引き
      final processed = processWaveform(raw, duration.inMilliseconds / 1000.0);

      // 固定フレームレートで表示範囲を制限（例：1秒 = 100フレーム）
      const int framesPerSecond = 100;
      final int displayLength = widget.displaySeconds * framesPerSecond;

      // ここを↓こう変える（切り取りなしで全体渡す）
      final List<double> clipped = processed;

      debugPrint("🎧 duration: ${duration.inMilliseconds} ms");
      debugPrint("🎧 normalized.length: ${processed.length}");
      debugPrint("🎧 displayLength: $displayLength");
      debugPrint("🎧 clipped.length: ${clipped.length}");

      setState(() {
        _audioDuration = duration;
        _waveformFuture = Future.value(clipped);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_audioDuration == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<double>>(
      future: _waveformFuture,
      builder: (context, snapshot) {
        final waveform = snapshot.data;

        if (waveform == null || waveform.isEmpty) {
          return const SizedBox(); // 空でも落ちないように
        }

        final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.2;

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: LineWavePainter(
              amplitudes: waveform,
              maxAmplitude: maxAmplitude,
              progress: widget.progress,
              samplesPerSecond: widget.sampleRate,
              displaySeconds: widget.displaySeconds,
            ),
          ),
        );
      },
    );
  }
}
