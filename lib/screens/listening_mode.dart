import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/subtitles_widget.dart';
import '../widgets/speed_selector.dart'; // 🆕 追加
import 'package:flutter/services.dart'; // for rootBundle

class ListeningMode extends StatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  State<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends State<ListeningMode> {
  final AudioPlayerService _audioService = AudioPlayerService();
  String? sampleFilePath;
  String subtitleText = '';
  double _currentSpeed = 1.0; // 🆕 再生速度

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();
  }

  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    setState(() {
      sampleFilePath = path;
    });
  }

  Future<void> _loadSubtitle() async {
    try {
      debugPrint('📂 読み込もうとしている字幕ファイル: ${widget.material.scriptPath}');
      final loadedText =
          await rootBundle.loadString(widget.material.scriptPath);
      setState(() {
        subtitleText = loadedText;
      });
    } catch (e) {
      debugPrint('❌ 字幕の読み込みに失敗: $e');
      setState(() {
        subtitleText = '字幕の読み込みに失敗しました。';
      });
    }
  }

  Future<void> _play() async {
    if (sampleFilePath != null) {
      await _audioService.setSpeed(_currentSpeed); // 🆕 再生速度を設定
      await _audioService.prepareAndPlayLocalFile(
          sampleFilePath!, _currentSpeed); // ← ✅ 正解
    }
  }

  Future<void> _pause() async {
    await _audioService.pause();
  }

  Future<void> _reset() async {
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
      appBar: AppBar(title: const Text('🎧 リスニングモード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: sampleFilePath != null
                  ? SampleWaveformWidget(
                      filePath: sampleFilePath!,
                      audioPlayerService: _audioService,
                      playbackSpeed: _currentSpeed, // 🆕 再生速度を渡す
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20),

            // 再生ボタン群
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 32),
                  onPressed: _play,
                ),
                IconButton(
                  icon: const Icon(Icons.pause, size: 32),
                  onPressed: _pause,
                ),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32),
                  onPressed: _reset,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🎚 スピード調整ウィジェット
            SpeedSelector(
              currentSpeed: _currentSpeed,
              onSpeedSelected: (speed) {
                setState(() {
                  _currentSpeed = speed;
                });
                _audioService.setSpeed(speed); // 再生中でも変更反映
              },
            ),

            const SizedBox(height: 20),

            // 字幕表示
            SubtitlesWidget(subtitleText: widget.material.scriptPath),
          ],
        ),
      ),
    );
  }
}
