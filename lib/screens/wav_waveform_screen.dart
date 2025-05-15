import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../utils/wav_utils.dart';
import '../widgets/wav_waveform_view.dart';

class WavWaveformScreen extends StatefulWidget {
  final String wavFilePath; // 🔥 録音ファイルのパスをここに渡す

  const WavWaveformScreen({super.key, required this.wavFilePath});

  @override
  State<WavWaveformScreen> createState() => _WavWaveformScreenState();
}

class _WavWaveformScreenState extends State<WavWaveformScreen> {
  List<double>? _amplitudes;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  Future<void> _loadWaveform() async {
    try {
      Uint8List bytes = await loadWavFile(widget.wavFilePath);
      final amplitudes = extractAmplitudesFromWav(bytes);

      setState(() {
        _amplitudes = amplitudes;
      });
    } catch (e) {
      debugPrint('❌ 波形読み込み失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📈 録音後の波形')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _amplitudes == null
            ? const Center(child: CircularProgressIndicator())
            : WavWaveformView(amplitudes: _amplitudes!),
      ),
    );
  }
}
