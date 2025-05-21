import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/subtitles_widget.dart'; // 必要ならこちらを使う
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
  String subtitleText = ''; // ← 追加：字幕データ保持用

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle(); // ← 字幕読み込み
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

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (sampleFilePath != null) {
      await _audioService.playLocalFile(sampleFilePath!);
    }
  }

  Future<void> _pause() async {
    await _audioService.pause();
  }

  Future<void> _reset() async {
    await _audioService.reset();
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
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20),
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
            // 字幕表示部分
            SizedBox(
              height: 120,
              width: double.infinity,
              child: SubtitlesWidget(subtitleText: subtitleText),
              // または Container+Text でもOK（デバッグ目的なら）
            ),
          ],
        ),
      ),
    );
  }
}
