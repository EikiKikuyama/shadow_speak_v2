import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/realtime_waveform_widget.dart';
import '../widgets/subtitles_widget.dart';
import '../screens/wav_waveform_screen.dart';
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
  String? sampleFilePath;
  int? countdownValue;
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
      appBar: AppBar(title: const Text('🗣 シャドーイングモード')),
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
                      playbackSpeed: _currentSpeed, // 🆕 速度渡す
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
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🎛️ 再生ボタン
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

            // 🎚️ 再生速度セレクター
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
