import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import 'package:flutter/services.dart';
import '../widgets/subtitles_widget.dart';

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
  double _currentSpeed = 1.0;
  bool _isPlaying = false;
  bool _hasPlayedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();
  }

  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    await _audioService.prepareLocalFile(path, _currentSpeed);
    setState(() {
      sampleFilePath = path;
    });
  }

  Future<void> _loadSubtitle() async {
    try {
      final loadedText =
          await rootBundle.loadString(widget.material.scriptPath);
      setState(() {
        subtitleText = loadedText;
      });
    } catch (e) {
      setState(() {
        subtitleText = '字幕の読み込みに失敗しました。';
      });
    }
  }

  Future<void> _play() async {
    if (sampleFilePath != null) {
      await _audioService.setSpeed(_currentSpeed);
      await _audioService.prepareAndPlayLocalFile(
          sampleFilePath!, _currentSpeed);
      setState(() {
        _isPlaying = true;
        _hasPlayedOnce = true;
      });
    }
  }

  Future<void> _pause() async {
    await _audioService.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _resume() async {
    await _audioService.resume();
    setState(() => _isPlaying = true);
  }

  Future<void> _reset() async {
    await _audioService.reset();
    setState(() {
      _isPlaying = false;
      _hasPlayedOnce = false;
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final subtitleHeight = screenHeight * 0.3;

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('🎧 リスニングモード', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 160,
              color: const Color(0xFF212121),
              child: sampleFilePath != null
                  ? ClipRect(
                      child: SampleWaveformWidget(
                        filePath: sampleFilePath!,
                        audioPlayerService: _audioService,
                        playbackSpeed: _currentSpeed,
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _pause();
                    } else {
                      if (_hasPlayedOnce) {
                        _resume();
                      } else {
                        _play();
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32, color: Colors.white),
                  onPressed: _reset,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SpeedSelector(
              currentSpeed: _currentSpeed,
              onSpeedSelected: (speed) {
                setState(() {
                  _currentSpeed = speed;
                });
                _audioService.setSpeed(speed);
              },
            ),
            const SizedBox(height: 20),
            Container(
              height: subtitleHeight,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6E3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SubtitlesWidget(
                    subtitleText: widget.material.scriptPath,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
