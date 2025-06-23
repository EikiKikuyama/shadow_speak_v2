import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/subtitles_widget.dart';
import '../widgets/playback_controls.dart';
import 'package:flutter/services.dart';

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
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();

    _audioService.positionStream.listen((pos) {
      setState(() => _currentPosition = pos);
    });
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

  Future<void> _togglePlayPause(bool isPlaying) async {
    if (sampleFilePath == null) return;
    await _audioService.setSpeed(_currentSpeed);
    if (isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.resume();
    }
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
    final screenHeight = MediaQuery.of(context).size.height;
    final subtitleHeight = screenHeight * 0.3;

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

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
                        height: 100,
                        progress: progress,
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            StreamBuilder<bool>(
              stream: _audioService.isPlayingStream,
              initialData: false,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return PlaybackControls(
                  isPlaying: isPlaying,
                  onPlayPauseToggle: () => _togglePlayPause(isPlaying),
                  onRestart: _reset,
                  onSeekForward: () {
                    _audioService
                        .seek(_currentPosition + const Duration(seconds: 5));
                  },
                  onSeekBackward: () {
                    _audioService
                        .seek(_currentPosition - const Duration(seconds: 5));
                  },
                );
              },
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
