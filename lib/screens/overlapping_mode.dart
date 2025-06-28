import 'dart:async';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';
import '../utils/subtitle_utils.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/subtitle_display.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';

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
  bool _isResetting = false;
  bool _hasPlayedOnce = false;

  String? sampleFilePath;
  int? countdownValue;
  double _currentSpeed = 1.0;
  late StreamSubscription<bool> _playingSubscription;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;

  List<SubtitleSegment> _subtitles = [];
  SubtitleSegment? _currentSubtitle;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();

    _playingSubscription = _audioService.isPlayingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          final current = getCurrentSubtitle(_subtitles, position);
          if (current != _currentSubtitle) {
            _currentSubtitle = current;
          }
        });
      }
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
    final filename = widget.material.scriptPath
        .split('/')
        .last
        .replaceAll('.txt', '')
        .replaceAll('.json', '');

    final data = await loadSubtitles(filename);
    setState(() {
      _subtitles = data;
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
      _isRecording = false;
      countdownValue = null;
      _hasPlayedOnce = false;
    });
  }

  Future<void> _pause() async {
    await _audioService.pause();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _resume() async {
    await _recorder.startRecording();
    await _audioService.resume();
    if (!mounted) return;
    setState(() {
      _isRecording = true;
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
    });
  }

  double _calculateProgress() {
    final total = _audioService.totalDuration?.inMilliseconds ?? 1;
    return _currentPosition.inMilliseconds / total;
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    _playingSubscription.cancel();
    _positionSubscription?.cancel();
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
                    Align(
                      alignment: Alignment.center,
                      child: ClipRect(
                        child: SampleWaveformWidget(
                          filePath: sampleFilePath!,
                          height: 100,
                          progress: _calculateProgress(),
                        ),
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
            PlaybackControls(
              isPlaying: _isPlaying,
              onPlayPauseToggle: () {
                if (!_hasPlayedOnce) {
                  _startCountdownAndPlay();
                } else if (_isPlaying) {
                  _pause();
                } else {
                  _resume();
                }
              },
              onRestart: _handleReset,
              onSeekForward: () => _audioService
                  .seek(_currentPosition + const Duration(seconds: 5)),
              onSeekBackward: () => _audioService
                  .seek(_currentPosition - const Duration(seconds: 5)),
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
                  child: _subtitles.isNotEmpty
                      ? SubtitleDisplay(
                          currentSubtitle: _currentSubtitle,
                          allSubtitles: _subtitles,
                        )
                      : const Center(child: Text("字幕を読み込み中…")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
