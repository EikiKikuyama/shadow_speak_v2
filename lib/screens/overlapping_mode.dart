import 'dart:async';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/subtitles_widget.dart';
import '../widgets/speed_selector.dart';

class OverlappingMode extends StatefulWidget {
  final PracticeMaterial material;

  const OverlappingMode({super.key, required this.material});

  @override
  State<OverlappingMode> createState() => _OverlappingModeState();
}

class _OverlappingModeState extends State<OverlappingMode> {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _audioService = AudioPlayerService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isResetting = false;
  bool _hasPlayedOnce = false;

  String? sampleFilePath;
  int? countdownValue;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
  }

  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    await _audioService.prepareLocalFile(path, _currentSpeed);
    setState(() {
      sampleFilePath = path;
    });
  }

  Future<void> _handleReset() async {
    _isResetting = true;
    await _audioService.reset();
    await _audioService.stop();

    if (sampleFilePath != null) {
      await _audioService.prepareLocalFile(sampleFilePath!, _currentSpeed);
    }

    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isRecording = false;
      countdownValue = null;
      _hasPlayedOnce = false;
    });
  }

  Future<void> _pause() async {
    await _audioService.pause();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _resume() async {
    await _audioService.resume();
    if (!mounted) return;
    setState(() {
      _isPlaying = true;
      _hasPlayedOnce = true;
    });
  }

  Future<void> _startCountdownAndPlay() async {
    if (_isPlaying || _isRecording || sampleFilePath == null) return;

    setState(() {
      countdownValue = 3;
      _isResetting = false;
    });

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _isResetting) return;
      setState(() => countdownValue = i - 1);
    }

    if (!mounted || _isResetting) return;

    setState(() {
      countdownValue = null;
      _isPlaying = true;
      _isRecording = true;
      _hasPlayedOnce = true;
    });

    await _recorder.startRecording();
    await _audioService.setSpeed(_currentSpeed);
    await _audioService.prepareAndPlayLocalFile(sampleFilePath!, _currentSpeed);

    final duration = _audioService.totalDuration ?? const Duration(seconds: 10);
    await Future.delayed(duration);

    await _audioService.stop();
    if (!mounted || _isResetting) return;

    setState(() {
      _isRecording = false;
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    _isResetting = true;
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
        title: const Text(
          '🎤 オーバーラッピングモード',
          style: TextStyle(color: Colors.white),
        ),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (sampleFilePath != null)
                    ClipRect(
                      child: SampleWaveformWidget(
                        filePath: sampleFilePath!,
                        audioPlayerService: _audioService,
                        playbackSpeed: _currentSpeed,
                      ),
                    ),
                  if (countdownValue != null)
                    Text(
                      countdownValue == 0 ? 'Go!' : countdownValue.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
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
                        _startCountdownAndPlay();
                      }
                    }
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.refresh, size: 32, color: Colors.white),
                  onPressed: _handleReset,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SpeedSelector(
              currentSpeed: _currentSpeed,
              onSpeedSelected: (speed) {
                setState(() => _currentSpeed = speed);
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
