import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _copiedSamplePath;
  String subtitleText = '';

  @override
  void initState() {
    super.initState();
    _prepareSampleAudio();
    _loadSubtitle();
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
      final text = await rootBundle.loadString(widget.material.scriptPath);
      if (!mounted) return;
      setState(() {
        subtitleText = text;
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
        screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight - 64;
    final waveformHeight = availableHeight * 0.18;
    final subtitleHeight = availableHeight * 0.25;

    Widget buildWaveformContainer({required Widget child}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: waveformHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
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
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('📊 録音波形の確認', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👤 見本波形',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _copiedSamplePath != null
                  ? buildWaveformContainer(
                      child: SampleWaveformWidget(
                        filePath: _copiedSamplePath!,
                        isAsset: false,
                        audioPlayerService: _audioService,
                        playbackSpeed: 1.0,
                      ),
                    )
                  : buildWaveformContainer(
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 16),
              const Text('🎙️ 録音波形',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildWaveformContainer(
                child: SampleWaveformWidget(
                  filePath: widget.wavFilePath,
                  isAsset: false,
                  audioPlayerService: _audioService,
                  playbackSpeed: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
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
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    subtitleText,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade700),
                ),
                child: const Center(
                  child: Text(
                    'AI採点へ（未実装）',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
