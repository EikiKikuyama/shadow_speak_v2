import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../screens/ai_scoring_screen.dart';
import '../services/subtitle_loader.dart';
import '../widgets/custom_app_bar.dart';

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
  String? _copiedSamplePath;
  String subtitleText = '';
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _prepareSampleAudio();
    _loadSubtitle();

    _audioService.positionStream.listen((pos) {
      if (!mounted || _audioService.totalDuration == null) return;
      final total = _audioService.totalDuration!.inMilliseconds;
      final current = pos.inMilliseconds;
      setState(() {
        _currentProgress = total > 0 ? current / total : 0.0;
      });
    });
  }

  Future<void> _prepareSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    await _audioService.prepareLocalFile(path, 1.0);
    if (!mounted) return;
    setState(() {
      _copiedSamplePath = path;
    });
  }

  Future<void> _loadSubtitle() async {
    try {
      final filename = widget.material.scriptPath
          .split('/')
          .last
          .replaceAll('.txt', '')
          .replaceAll('.json', '');

      final data = await loadSubtitles(filename);
      if (!mounted) return;
      setState(() {
        subtitleText = data.map((s) => s.text).join('\n'); // 全文を表示用に連結
      });
    } catch (e) {
      debugPrint('❌ 字幕読み込み失敗: $e');
      setState(() {
        subtitleText = '字幕の読み込みに失敗しました。';
      });
    }
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - MediaQuery.of(context).padding.top - 64;
    final waveformHeight = availableHeight * 0.18;
    final subtitleHeight = availableHeight * 0.25;

    Widget buildWaveformContainer(
        {required Widget child, required Color background}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: waveformHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF001f3f), // 紺背景
      appBar: const CustomAppBar(
        title: '自己チェックシート',
        backgroundColor: Color(0xFF001f3f),
        titleColor: Colors.white,
        iconColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('あなたの音声の波形',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              buildWaveformContainer(
                background: Colors.white,
                child: SampleWaveformWidget(
                  filePath: widget.wavFilePath,
                  isAsset: false,
                  height: waveformHeight,
                  progress: _currentProgress,
                ),
              ),
              const SizedBox(height: 24),
              const Text('見本の音声の波形',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              _copiedSamplePath != null
                  ? buildWaveformContainer(
                      background: Colors.black,
                      child: SampleWaveformWidget(
                        filePath: _copiedSamplePath!,
                        isAsset: false,
                        height: waveformHeight,
                        progress: _currentProgress,
                      ),
                    )
                  : buildWaveformContainer(
                      background: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 36),
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon:
                        const Icon(Icons.replay, color: Colors.white, size: 32),
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: subtitleHeight,
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AiScoringScreen(
                          whisperScore: 95,
                          prosodyScore: 95,
                          referenceText:
                              'attention please, the next train bound for Tokyo will arrive at platform number 2.',
                          transcribedText:
                              'attention please, the next train bound for Tokyo will arrive at platform No2. please behind the yellow line...',
                          prosodyFeedback:
                              '抑揚は全体的に安定していますが、語尾がやや聞き取りづらい箇所があります。',
                          pronunciationFeedback:
                              '「Tokyo」や「yellow line」など、いくつかの単語の発音が不明瞭です。音節を意識して練習してみましょう。',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'AI採点モードへ →',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
