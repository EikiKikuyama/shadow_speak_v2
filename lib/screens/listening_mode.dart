import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';

import '../utils/subtitle_utils.dart';

import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';
import '../widgets/subtitle_display.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/word_subtitle_bar.dart';
import '../widgets/ab_repeat_controls.dart';
// 追加
import 'package:shadow_speak_v2/settings/settings_controller.dart';

class ListeningMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  ConsumerState<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends ConsumerState<ListeningMode> {
  final AudioPlayerService _audioService = AudioPlayerService();

  // === ABリピート用 ===
  Duration? _abStart;
  Duration? _abEnd;
  ABRepeatState _abState = ABRepeatState.idle;
  bool _dim = false; // 短時間の暗転フィードバック
  String _aLabel = "--";
  String _bLabel = "--";

  bool _isSeekingForLoop = false;
  DateTime _lastSeekAt = DateTime.fromMillisecondsSinceEpoch(0);

  // === 再生・字幕 ===
  String? sampleFilePath;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;

  List<SubtitleSegment> _subtitles = [];
  List<WordSegment> _wordSegments = [];
  SubtitleSegment? _currentSubtitle;
  StreamSubscription<Duration>? _positionSubscription;

  String fullText = "";
  int currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();

    _positionSubscription = _audioService.positionStream.listen((pos) async {
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      final current = getCurrentSubtitle(_subtitles, pos);
      if (current != _currentSubtitle) {
        setState(() => _currentSubtitle = current);
      }

      // ===== ABループ処理 =====
      if (_abState == ABRepeatState.ready &&
          _abStart != null &&
          _abEnd != null) {
        const epsilon = Duration(milliseconds: 30);
        final now = DateTime.now();
        final inCooldown =
            now.difference(_lastSeekAt) < const Duration(milliseconds: 120);

        if (!_isSeekingForLoop && !inCooldown && pos + epsilon >= _abEnd!) {
          _isSeekingForLoop = true;
          _lastSeekAt = now;
          try {
            await _audioService.seek(_abStart!);
            await _audioService.resume();
          } finally {
            _isSeekingForLoop = false;
          }
        }
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
        .replaceFirst('assets/subtitles/', '')
        .replaceAll('.json', '')
        .replaceAll('.txt', '');

    final data = await loadSubtitles(filename);
    final wordData = await loadWordSegments(filename);
    setState(() {
      _subtitles = data;
      _wordSegments = wordData;
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

  // ========== ABハンドラ ==========
  String _fmt(Duration d) {
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final m = d.inMinutes.toString();
    return '$m:$s.$ms';
  }

  void _flashDim({int ms = 200}) {
    setState(() => _dim = true);
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _dim = false);
    });
  }

  Future<void> _handleSetA() async {
    setState(() {
      _abState = ABRepeatState.selectingA; // A選択モードへ
      _dim = true; // 暗転を維持（確定まで）
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A地点にしたい本文をタップしてください')),
      );
    }
  }

  Future<void> _handleSetB() async {
    setState(() {
      _abState = (_abStart == null)
          ? ABRepeatState.selectingA // まだAが無いならAから
          : ABRepeatState.selectingB; // B選択モードへ
      _dim = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_abStart == null
                ? '先にA地点を選んでください（本文をタップ）'
                : 'B地点にしたい本文をタップしてください')),
      );
    }
  }

  void _handleReset() {
    setState(() {
      _abStart = null;
      _abEnd = null;
      _aLabel = "--";
      _bLabel = "--";
      _abState = ABRepeatState.idle;
      _dim = false; // 暗転も解除
    });
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
      body: Stack(
        children: [
          // ===== メインUI =====
          Column(
            children: [
              // 字幕（全体）
              Container(
                height: subtitleHeight,
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _subtitles.isNotEmpty
                    ? // build() の SubtitleDisplay 呼び出しを修正
                    SubtitleDisplay(
                        currentTime: _currentPosition,
                        allSubtitles: _subtitles,
                        highlightColor: Colors.blue,
                        defaultColor: textColor,
                        abState: _abState,
                        abStart: _abStart,
                        abEnd: _abEnd,
                        selectedA: _abStart, // ★ 追加
                        selectedB: _abEnd, // ★ 追加
                        onSelectSubtitle: (start, end) {
                          // セグメントタップ時のフォールバック（任意）
                        },
                        onWordTap: (word) {
                          final wStart = Duration(
                              milliseconds: (word.start * 1000).toInt());
                          final wEnd =
                              Duration(milliseconds: (word.end * 1000).toInt());

                          setState(() {
                            if (_abState == ABRepeatState.selectingA) {
                              _abStart = wStart;
                              _aLabel = _fmt(wStart);
                              _abEnd = null;
                              _bLabel = "--";
                              _abState = ABRepeatState.selectingB; // 次はB
                              _dim = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('次にB地点にしたい単語をタップしてください')),
                              );
                            } else if (_abState == ABRepeatState.selectingB) {
                              // 最短区間 200ms
                              if (wEnd <=
                                  (_abStart ?? Duration.zero) +
                                      const Duration(milliseconds: 200)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('BはAより少し後にしてください（>=200ms）')),
                                );
                                return;
                              }
                              _abEnd = wEnd;
                              _bLabel = _fmt(wEnd);
                              _abState = ABRepeatState.ready; // 完了
                              _dim = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AB区間を設定しました')),
                              );
                            }
                          });
                        },
                      )
                    : Center(
                        child: Text(
                          "字幕を読み込み中…",
                          style: TextStyle(color: textColor),
                        ),
                      ),
              ),

              // 波形＋カラオケ
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
                                  sampleRate: 100,
                                  displaySeconds: 4,
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: _wordSegments.isNotEmpty
                            ? FocusedKaraokeSubtitle(
                                wordSegments: _wordSegments,
                                currentTime: _currentPosition,
                                highlightColor: Colors.orange,
                                defaultColor: textColor,
                              )
                            : Center(
                                child: Text("字幕を読み込み中…",
                                    style: TextStyle(color: textColor)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // 下部コントロール群
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
                          onSeekForward: () => _audioService.seek(
                              _currentPosition + const Duration(seconds: 5)),
                          onSeekBackward: () => _audioService.seek(
                              _currentPosition - const Duration(seconds: 5)),
                        );
                      },
                    ),

                    // === 1ボタンABコントローラー ===
                    ABRepeatControls(
                      aTime: _aLabel,
                      bTime: _bLabel,
                      onSetA: _handleSetA, // selectingAへ
                      onSetB: _handleSetB, // 未使用
                      onReset: _handleReset,
                    ),

                    const SizedBox(height: 12),

                    // 再生速度
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

          // ===== 暗転オーバーレイ =====
          // 置き換え（onTap付き GestureDetector をやめる）
          if (_dim)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // タップを全部下に通す
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
        ],
      ),
    );
  }
}
