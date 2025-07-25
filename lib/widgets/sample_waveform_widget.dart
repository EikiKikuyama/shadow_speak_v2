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

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.height,
    required this.progress,
    this.isAsset = false,
    this.showComparison = false,
    this.comparisonAssetPath,
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
    try {
      final player = AudioPlayer();
      await player.setFilePath(widget.filePath);
      final duration = player.duration ?? Duration.zero;
      await player.dispose();

      List<double> raw = widget.isAsset
          ? await extractWaveformFromAssets(widget.filePath)
          : extractWaveform(File(widget.filePath));

      if (raw.isEmpty) {
        debugPrint("⚠️ 波形が空です（${widget.filePath}）");
      }

      final processed = processWaveform(raw); // ✅ ← 波形間引き処理を復活！

      setState(() {
        _audioDuration = duration;
        _waveformFuture = Future.value(processed);
      });
    } catch (e) {
      debugPrint("❌ 波形読み込みエラー: $e");
      setState(() {
        _audioDuration = Duration.zero;
        _waveformFuture = Future.value([]);
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
            ),
          ),
        );
      },
    );
  }
}
