import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart';

class OverlappingMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;

  const OverlappingMode({super.key, required this.material});

  @override
  ConsumerState<OverlappingMode> createState() => _OverlappingModeState();
}

class _OverlappingModeState extends ConsumerState<OverlappingMode> {
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
        .replaceFirst('assets/subtitles/', '') // パス先頭だけ削除
        .replaceAll('.json', '')
        .replaceAll('.txt', '');

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
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final dir = await getApplicationDocumentsDirectory();

    final safeLevel = widget.material.level.replaceAll(' ', '_');
    final safeTitle = widget.material.title.replaceAll(' ', '_');

    final savePath = '${dir.path}/shadow_speak/recordings/'
        '${safeLevel}_${safeTitle}_$timestamp.wav';

    await _recorder.startRecording(
      path: savePath,
      level: widget.material.level,
      title: widget.material.title,
    );

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
    final settingsController = ref.watch(settingsControllerProvider);
    final isDark = settingsController.isDarkMode;

    final backgroundColor =
        isDark ? const Color(0xFF001F3F) : const Color(0xFFF4F1FA);
    final textColor = isDark ? Colors.white : Colors.black;
    final sliderActiveColor = isDark ? Colors.white : Colors.black;
    final sliderInactiveColor = isDark ? Colors.white24 : Colors.black26;

    final screenHeight = MediaQuery.of(context).size.height;
    final subtitleHeight = screenHeight * 0.3;

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '🎤 オーバーラッピングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icon.png'),
                        fit: BoxFit.cover,
                      ),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Center(
                      child: Text(
                        _currentSubtitle?.text ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Container(
                    height: subtitleHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: _subtitles.isNotEmpty
                        ? SubtitleDisplay(
                            currentSubtitle: _currentSubtitle,
                            allSubtitles: _subtitles,
                            highlightColor: Colors.blue,
                            defaultColor: textColor,
                          )
                        : Center(
                            child: Text(
                              "字幕を読み込み中…",
                              style: TextStyle(color: textColor),
                            ),
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
