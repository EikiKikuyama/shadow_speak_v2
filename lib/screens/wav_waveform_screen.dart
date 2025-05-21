import 'dart:io';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../utils/waveform_extractor.dart';
import '../painters/line_wave_painter.dart';
import '../services/audio_player_service.dart';
import '../widgets/subtitles_widget.dart';

class WavWaveformScreen extends StatefulWidget {
  final String wavFilePath;
  final PracticeMaterial material;

  const WavWaveformScreen({
    super.key,
    required this.wavFilePath,
    required this.material,
  });

  @override
  State<WavWaveformScreen> createState() => _WavWaveformScreenState();
}

class _WavWaveformScreenState extends State<WavWaveformScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  late Future<Map<String, dynamic>> _waveformsFuture;

  @override
  void initState() {
    super.initState();
    _waveformsFuture = _loadBothWaveforms();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadBothWaveforms() async {
    // 録音波形
    final recordedFile = File(widget.wavFilePath);
    final recordedRaw = extractWaveform(recordedFile);
    final recordedWaveform = processWaveform(recordedRaw);
    final recordedMax = recordedWaveform.reduce((a, b) => a > b ? a : b) * 1.5;

    // 見本波形
    final samplePath =
        await _audioService.copyAssetToFile(widget.material.audioPath);
    final sampleFile = File(samplePath);
    final sampleRaw = extractWaveform(sampleFile);
    final sampleWaveform = processWaveform(sampleRaw);
    final sampleMax = sampleWaveform.reduce((a, b) => a > b ? a : b) * 1.5;

    return {
      'recorded': recordedWaveform,
      'recordedMax': recordedMax,
      'sample': sampleWaveform,
      'sampleMax': sampleMax,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔁 録音と見本の比較")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _waveformsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recordedWaveform = snapshot.data!['recorded'] as List<double>;
          final recordedMax = snapshot.data!['recordedMax'] as double;
          final sampleWaveform = snapshot.data!['sample'] as List<double>;
          final sampleMax = snapshot.data!['sampleMax'] as double;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // 🔵 見本波形（再生に同期）
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: StreamBuilder<Duration>(
                    stream: _audioService.onPositionChanged,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioService.totalDuration ??
                          Duration(milliseconds: 1);
                      final progress =
                          position.inMilliseconds / duration.inMilliseconds;

                      return CustomPaint(
                        painter: LineWavePainter(
                          amplitudes: sampleWaveform,
                          maxAmplitude: sampleMax,
                          progress: progress.clamp(0.0, 1.0),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // 🔴 録音波形（再生に同期）
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: StreamBuilder<Duration>(
                    stream: _audioService.onPositionChanged,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioService.totalDuration ??
                          Duration(milliseconds: 1);
                      final progress =
                          position.inMilliseconds / duration.inMilliseconds;

                      return CustomPaint(
                        painter: LineWavePainter(
                          amplitudes: recordedWaveform,
                          maxAmplitude: recordedMax,
                          progress: progress.clamp(0.0, 1.0),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // 📃 字幕表示（SubtitlesWidget 内部でファイルを読み込む）
                SubtitlesWidget(subtitleText: widget.material.scriptPath),
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
            ),
          );
        },
      ),
    );
  }
}
