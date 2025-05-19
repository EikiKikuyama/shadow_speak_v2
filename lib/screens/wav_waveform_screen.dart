import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/waveform_extractor.dart';
import '../painters/line_wave_painter.dart';
import '../services/audio_player_service.dart';

class WavWaveformScreen extends StatefulWidget {
  final String wavFilePath;

  const WavWaveformScreen({super.key, required this.wavFilePath});

  @override
  State<WavWaveformScreen> createState() => _WavWaveformScreenState();
}

class _WavWaveformScreenState extends State<WavWaveformScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  late Future<List<double>> _waveformFuture;

  @override
  void initState() {
    super.initState();
    _waveformFuture = _loadWaveform();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<List<double>> _loadWaveform() async {
    final file = File(widget.wavFilePath);
    final raw = extractWaveform(file);
    return processWaveform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("録音後の波形表示")),
      body: FutureBuilder<List<double>>(
        future: _waveformFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final waveform = snapshot.data!;
          final maxAmplitude = waveform.reduce((a, b) => a > b ? a : b) * 1.5;

          return Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: StreamBuilder<Duration>(
                  stream: _audioService.onPositionChanged, // ✅ 再生位置を監視
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _audioService.totalDuration ??
                        Duration(milliseconds: 1);
                    final progress =
                        position.inMilliseconds / duration.inMilliseconds;

                    return CustomPaint(
                      painter: LineWavePainter(
                        amplitudes: waveform,
                        maxAmplitude: maxAmplitude,
                        progress: progress.clamp(0.0, 1.0), // ✅ 安全に進行度を渡す
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("再生"),
                    onPressed: () async {
                      await _audioService.playLocalFile(widget.wavFilePath);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("戻る"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
