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
import 'package:intl/intl.dart'; // ← DateFormat用
import 'package:path_provider/path_provider.dart'; // ← getApplicationDocumentsDirectory用
import 'dart:io';
import '../widgets/custom_app_bar.dart'; // ← カスタムアプリバー用

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
    // 保存先パスを作成
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final dir = await getApplicationDocumentsDirectory();

    // ファイル名を安全に（スペースや記号を避けるため）
    final safeLevel = widget.material.level.replaceAll(' ', '_');
    final safeTitle = widget.material.title.replaceAll(' ', '_');

    final savePath = '${dir.path}/shadow_speak/recordings/'
        '${safeLevel}_${safeTitle}_$timestamp.wav';

    // 録音開始（ファイル名付き）
    await _recorder.startRecording(
      path: savePath,
      level: widget.material.level,
      title: widget.material.title,
    );

    // 音声再生
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

    Future<void> someFunction() async {
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final timestamp = formatter.format(now);

      final directory = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${directory.path}/shadow_speak/recordings');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final filename =
          '${widget.material.level}_${widget.material.title}_$timestamp.wav';
      final savePath = '${saveDir.path}/$filename';

      await _recorder.startRecording(
        path: savePath,
        level: widget.material.level,
        title: widget.material.title,
      );
    }

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

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF001F3F), // 🎨 統一された深紺色
      appBar: const CustomAppBar(
        title: '🎤 オーバーラッピングモード',
        backgroundColor: Color(0xFF001F3F),
        titleColor: Colors.white,
        iconColor: Colors.white,
      ),

      body: Column(
        children: [
          // 🔼 アイコンバナー（統一デザイン）
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
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
                  // 🔊 波形表示（白背景・中央に表示）
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
                              color: Colors.black, // 白背景に黒字
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 💬 波形下に字幕（1行仮表示）
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        _currentSubtitle?.text ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // 📝 字幕全文表示（スクロール可能）
                  Container(
                    height: subtitleHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: _subtitles.isNotEmpty
                            ? SubtitleDisplay(
                                currentSubtitle: _currentSubtitle,
                                allSubtitles: _subtitles,
                              )
                            : const Center(
                                child: Text(
                                  "字幕を読み込み中…",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ⏯ 下部コントロール（再生・速度調整）
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
