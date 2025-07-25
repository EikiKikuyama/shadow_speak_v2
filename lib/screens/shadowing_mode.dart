import 'dart:async';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';
import '../utils/subtitle_utils.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';
import '../widgets/custom_app_bar.dart';

class ShadowingMode extends StatefulWidget {
  final PracticeMaterial material;

  const ShadowingMode({super.key, required this.material});

  @override
  State<ShadowingMode> createState() => _ShadowingModeState();
}

class _ShadowingModeState extends State<ShadowingMode> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isResetting = false;
  bool _hasPlayedOnce = false;
  bool _isPlaying = false;
  String? sampleFilePath;
  int? countdownValue;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  List<SubtitleSegment> _subtitles = [];
  SubtitleSegment? _currentSubtitle;
  final List<String> _tips = [
    "Repeat after the speaker with the same rhythm.",
    "Focus on intonation and stress.",
    "Try to mimic the speaker's emotion.",
    "Close your eyes and just listen once.",
    "Pause and shadow short chunks."
  ];
  late final String _randomTip;

  @override
  void initState() {
    super.initState();
    _randomTip = (_tips..shuffle()).first;
    _loadSampleAudio();
    _loadSubtitle();
    _playingSubscription = _audioService.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        final current = getCurrentSubtitle(_subtitles, position);
        if (current != _currentSubtitle) {
          _currentSubtitle = current;
        }
      });
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

  Future<void> _startCountdownAndPlay() async {
    if (_isPlaying || sampleFilePath == null) return;
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
      _hasPlayedOnce = true;
    });
    await _audioService.setSpeed(_currentSpeed);
    await _audioService.prepareAndPlayLocalFile(sampleFilePath!, _currentSpeed);
  }

  Future<void> _pause() async {
    await _audioService.pause();
  }

  Future<void> _resume() async {
    await _audioService.resume();
    setState(() {
      _hasPlayedOnce = true;
    });
  }

  Future<void> _handleReset() async {
    _isResetting = true;
    await _audioService.reset();
    await _audioService.stop();
    if (sampleFilePath != null) {
      await _audioService.prepareLocalFile(sampleFilePath!, _currentSpeed);
    }
    setState(() {
      _isPlaying = false;
      _hasPlayedOnce = false;
      countdownValue = null;
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _isResetting = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: const CustomAppBar(
        title: '🗣 シャドーイングモード',
        backgroundColor: Color(0xFF001F3F),
        titleColor: Colors.white,
        iconColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icon.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _randomTip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_currentSubtitle?.translation.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        _currentSubtitle!.translation,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    height: 160,
                    color: Colors.white,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (sampleFilePath != null)
                          ClipRect(
                            child: SampleWaveformWidget(
                              filePath: sampleFilePath!,
                              height: 100,
                              progress: progress,
                            ),
                          ),
                        if (countdownValue != null)
                          Text(
                            countdownValue == 0
                                ? 'Go!'
                                : countdownValue.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                if (total != null && total.inMilliseconds > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Slider(
                      value: _currentPosition.inMilliseconds
                          .toDouble()
                          .clamp(0, total.inMilliseconds.toDouble()),
                      min: 0,
                      max: total.inMilliseconds.toDouble(),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        setState(() {
                          _currentPosition =
                              Duration(milliseconds: value.toInt());
                        });
                      },
                      onChangeEnd: (value) {
                        _audioService
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
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
                const SizedBox(height: 12),
                SpeedSelector(
                  currentSpeed: _currentSpeed,
                  onSpeedSelected: (speed) {
                    setState(() => _currentSpeed = speed);
                    _audioService.setSpeed(speed);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
