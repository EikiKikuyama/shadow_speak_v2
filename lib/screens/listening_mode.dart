import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';
import '../utils/subtitle_utils.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';
import '../widgets/subtitle_display.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';

class ListeningMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  ConsumerState<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends ConsumerState<ListeningMode> {
  final AudioPlayerService _audioService = AudioPlayerService();
  String? sampleFilePath;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;

  List<SubtitleSegment> _subtitles = [];
  SubtitleSegment? _currentSubtitle;
  StreamSubscription<Duration>? _positionSubscription;

  String fullText = "";
  int currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();

    _positionSubscription = _audioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      final current = getCurrentSubtitle(_subtitles, pos);
      if (current != _currentSubtitle) {
        setState(() {
          _currentSubtitle = current;
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
      fullText = _subtitles.map((s) => s.text).join(" ");
    });
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
    _positionSubscription?.cancel();
    _audioService.stop();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);
    final isDark = settingsController.isDarkMode;

    final backgroundColor =
        isDark ? const Color(0xFF001F3F) : const Color(0xFFF4F1FA);
    final textColor = isDark ? Colors.white : Colors.black;
    final waveColor = isDark ? Colors.white : Colors.grey[200];
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
        title: '🎧 リスニングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
      ),
      body: Column(
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
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 160,
                    color: waveColor,
                    child: sampleFilePath != null
                        ? ClipRect(
                            child: SampleWaveformWidget(
                              filePath: sampleFilePath!,
                              height: 100,
                              progress: progress,
                              sampleRate: 100, // 60 samples per second
                              displaySeconds: 4, // 1 second of audio
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Center(
                      child: Text(
                        "波形のところだけ字幕表示はここ",
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
                StreamBuilder<bool>(
                  stream: _audioService.isPlayingStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return PlaybackControls(
                      isPlaying: isPlaying,
                      onPlayPauseToggle: () => _togglePlayPause(isPlaying),
                      onRestart: _reset,
                      onSeekForward: () => _audioService
                          .seek(_currentPosition + const Duration(seconds: 5)),
                      onSeekBackward: () => _audioService
                          .seek(_currentPosition - const Duration(seconds: 5)),
                    );
                  },
                ),
                const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
