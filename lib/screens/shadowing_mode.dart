// lib/screens/shadowing_mode.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';
import '../utils/subtitle_utils.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';
import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart';

class ShadowingMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;
  const ShadowingMode({super.key, required this.material});

  @override
  ConsumerState<ShadowingMode> createState() => _ShadowingModeState();
}

class _ShadowingModeState extends ConsumerState<ShadowingMode> {
  // ===== Audio (sample) =====
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

  // ===== Subtitles =====
  List<SubtitleSegment> _subtitles = [];
  SubtitleSegment? _currentSubtitle;

  // ===== Tips =====
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

  // ===== Sample audio & subtitles =====
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
        .replaceFirst('assets/subtitles/', '')
        .replaceAll('.json', '')
        .replaceAll('.txt', '');
    final data = await loadSubtitles(filename);
    setState(() {
      _subtitles = data;
    });
  }

  // ===== Controls =====
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

    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _hasPlayedOnce = false;
      countdownValue = null;
      _currentPosition = Duration.zero;
    });
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);
    final isDarkMode = settingsController.isDarkMode;

    final backgroundColor = isDarkMode ? const Color(0xFF001F3F) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleBoxColor = isDarkMode ? Colors.white10 : Colors.grey[200];
    final sliderActiveColor = isDarkMode ? Colors.white : Colors.black;
    final sliderInactiveColor = isDarkMode ? Colors.white24 : Colors.black26;

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '🗣 シャドーイングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
        actions: [],
      ),
      body: Column(
        children: [
          // Tip
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: subtitleBoxColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _randomTip,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Main
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // サンプル波形のみ
                  Container(
                    width: double.infinity,
                    height: 160,
                    color: isDarkMode ? Colors.white : Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (sampleFilePath != null)
                          ClipRect(
                            child: SampleWaveformWidget(
                              filePath: sampleFilePath!,
                              height: 100,
                              progress: progress,
                              // displaySeconds: 3, // ←好みで。未指定なら既定値
                            ),
                          ),
                        if (countdownValue != null)
                          Text(
                            countdownValue == 0 ? 'Go!' : '$countdownValue',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.black : Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls
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
                      activeColor: sliderActiveColor,
                      inactiveColor: sliderInactiveColor,
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
