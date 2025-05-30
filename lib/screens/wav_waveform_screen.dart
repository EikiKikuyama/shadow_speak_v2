import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';

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
  bool _isPlaying = false;

  Future<void> _play() async {
    setState(() => _isPlaying = true);
    await _audioService.prepareAndPlayLocalFile(widget.wavFilePath, 1.0);
  }

  Future<void> _pause() async {
    setState(() => _isPlaying = false);
    await _audioService.pause();
  }

  Future<void> _reset() async {
    setState(() => _isPlaying = false);
    await _audioService.reset();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 録音波形の確認')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 👤 見本波形（上）
            SampleWaveformWidget(
              filePath: widget.material.audioPath,
              audioPlayerService: _audioService,
              playbackSpeed: 1.0,
              height: 100,
            ),
            const SizedBox(height: 16),
            // 🎙️ 録音波形（下）
            SampleWaveformWidget(
              filePath: widget.wavFilePath,
              audioPlayerService: _audioService,
              playbackSpeed: 1.0,
              height: 100,
            ),
            const SizedBox(height: 24),
            // ▶️ / ⏸ / 🔁
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                  onPressed: _isPlaying ? _pause : _play,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32),
                  onPressed: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
