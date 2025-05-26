import 'dart:async';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/realtime_waveform_widget.dart';
import '../screens/wav_waveform_screen.dart';
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
  String? sampleFilePath;
  int? countdownValue;

  double _currentSpeed = 1.0; // 🆕 再生速度

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
  }

  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    setState(() {
      sampleFilePath = path;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _startCountdownAndPlay() async {
    if (_isPlaying || _isRecording || sampleFilePath == null) return;

    setState(() {
      countdownValue = 3;
    });

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        countdownValue = i - 1;
      });
    }

    setState(() {
      countdownValue = null;
      _isPlaying = true;
      _isRecording = true;
    });

    await _recorder.startRecording();

    // 🆕 再生速度を設定
    await _audioService.setSpeed(_currentSpeed);

    // 再生と同時に再生終了まで待つ
    await _audioService.prepareAndPlayLocalFile(
        sampleFilePath!, _currentSpeed); // ← ✅ 正解

    final duration = _audioService.totalDuration ?? const Duration(seconds: 10);
    await Future.delayed(duration);

    final path = await _recorder.stopRecording();
    await _audioService.stop();

    setState(() {
      _isRecording = false;
      _isPlaying = false;
    });

    if (path != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WavWaveformScreen(
            wavFilePath: path,
            material: widget.material,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 オーバーラッピングモード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (sampleFilePath != null)
                    SampleWaveformWidget(
                      filePath: sampleFilePath!,
                      audioPlayerService: _audioService,
                      playbackSpeed: _currentSpeed, // 🆕 再生速度を渡す
                    ),
                  RealtimeWaveformWidget(
                    amplitudeStream: _recorder.amplitudeStream,
                    height: 150,
                  ),
                  if (countdownValue != null)
                    Text(
                      countdownValue == 0 ? 'Go!' : countdownValue.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32),
                  onPressed: _startCountdownAndPlay,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 🆕 再生スピード選択
            SpeedSelector(
              currentSpeed: _currentSpeed,
              onSpeedSelected: (speed) {
                setState(() {
                  _currentSpeed = speed;
                });
                _audioService.setSpeed(speed); // 再生中にも反映
              },
            ),
            const SizedBox(height: 20),
// ✅ 字幕だけスクロール可能に
            Container(
              height: 300,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child:
                    SubtitlesWidget(subtitleText: widget.material.scriptPath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
