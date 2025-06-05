import 'dart:async';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';

class ShadowingMode extends StatefulWidget {
  final PracticeMaterial material;

  const ShadowingMode({super.key, required this.material});

  @override
  State<ShadowingMode> createState() => _ShadowingModeState();
}

class _ShadowingModeState extends State<ShadowingMode> {
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

  Future<void> _startCountdownAndPlay() async {
    if (_isPlaying || _isRecording || sampleFilePath == null) return;

    setState(() {
      countdownValue = 3;
      _isResetting = false;
    });

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _isResetting) return;
      setState(() {
        countdownValue = i - 1;
      });
    }

    if (!mounted || _isResetting) return;

    setState(() {
      countdownValue = null;
      _isPlaying = true;
      _isRecording = true;
      _hasPlayedOnce = true;
    });

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

  Future<void> _pause() async {
    await _audioService.pause();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isRecording = false;
    });
  }

  Future<void> _resume() async {
    await _audioService.resume();
    if (!mounted) return;
    setState(() {
      _isPlaying = true;
      _isRecording = true;
    });
  }

  Future<void> _handleReset() async {
    _isResetting = true;
    await _audioService.stop();
    if (sampleFilePath != null) {
      await _audioService.prepareLocalFile(sampleFilePath!, _currentSpeed);
    }
    setState(() {
      _isPlaying = false;
      _isRecording = false;
      _hasPlayedOnce = false;
      countdownValue = null;
    });
  }

  @override
  void dispose() {
    _isResetting = true;
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          '🗣 シャドーイングモード',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 波形エリア
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

            // 再生・停止・リセット
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

            // スピードセレクター
            SpeedSelector(
              currentSpeed: _currentSpeed,
              onSpeedSelected: (speed) {
                setState(() {
                  _currentSpeed = speed;
                });
                _audioService.setSpeed(speed);
              },
            ),
          ],
        ),
      ),
    );
  }
}
