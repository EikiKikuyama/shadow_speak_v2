import 'dart:io';
import 'package:flutter/material.dart';
import '../painters/line_wave_painter.dart';
import '../utils/waveform_extractor.dart';

class SampleWaveformWidget extends StatefulWidget {
  final String filePath;
  final double height;
  final double progress;
  final bool isAsset;

  const SampleWaveformWidget({
    super.key,
    required this.filePath,
    required this.height,
    required this.progress,
    this.isAsset = false,
  });

  @override
  State<SampleWaveformWidget> createState() => _SampleWaveformWidgetState();
}

class _SampleWaveformWidgetState extends State<SampleWaveformWidget> {
  late Future<List<double>> _waveformFuture;

  @override
  void initState() {
    super.initState();
    _waveformFuture = _loadAndProcessWaveform();
  }

  Future<List<double>> _loadAndProcessWaveform() async {
    debugPrint(
        "🧪 SampleWaveformWidget: filePath = ${widget.filePath}, isAsset = ${widget.isAsset}");

    try {
      List<double> raw = widget.isAsset
          ? await extractWaveformFromAssets(widget.filePath)
          : extractWaveform(File(widget.filePath));

      if (raw.isEmpty) {
        debugPrint("⚠️ 抽出された波形が空です（${widget.filePath}）");
        return [];
      }

      final processed = processWaveform(raw);
      debugPrint("🔢 processed.length: ${processed.length}");
      return processed;
    } catch (e) {
      debugPrint("❌ 波形抽出エラー: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _waveformFuture,
      builder: (context, snapshot) {
        final waveform = snapshot.data;

        if (waveform == null || waveform.isEmpty) {
          debugPrint(
              "[Sample]⚠️ waveform（processed）がnullまたは空です。描画スキップ（${widget.filePath}）");
          return const SizedBox();
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
