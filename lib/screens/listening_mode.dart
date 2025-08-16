import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../painters/line_wave_painter.dart';
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
import 'package:shadow_speak_v2/settings/settings_controller.dart';
import '../services/simple_dictionary.dart';
import '../widgets/word_meaning_sheet.dart';

class ListeningMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  ConsumerState<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends ConsumerState<ListeningMode> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final _dict = SimpleDictionary(); // ① 辞書を保持

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

  // 単語ワンショット再生用
  Duration? _wordPlayEnd;
  bool _isWordPlaying = false;
  Timer? _wordStopTimer; // ← 追加：単語停止用タイマー

  static const int _kTailPadMs = 150; // 好みで 80〜150ms
  Duration _paddedEnd(Duration end) {
    final total = _audioService.totalDuration;
    final padded = end + const Duration(milliseconds: _kTailPadMs);
    if (total == null) return padded;
    return padded <= total ? padded : total;
  }

// ABループを一時停止するためのフラグ（単語再生中はABを無効化）
  bool _suppressABDuringWord = false;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();
    _dict.init(); // ② 起動時に辞書読み込み

    _positionSubscription = _audioService.positionStream.listen((pos) async {
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      final current = getCurrentSubtitle(_subtitles, pos);
      if (current != _currentSubtitle) {
        setState(() => _currentSubtitle = current);
      }

      // ===== ABループ処理 =====
      // ABループ（単語再生中は抑制）
      if (!_suppressABDuringWord &&
          _abState == ABRepeatState.ready &&
          _abStart != null &&
          _abEnd != null) {
        // B確定時に _abEnd は _paddedEnd() で+100〜120ms 済み前提
        final end = _abEnd!;
        const lookahead = Duration(milliseconds: 40); // 少し手前でトリガー
        final now = DateTime.now();
        final inCooldown =
            now.difference(_lastSeekAt) < const Duration(milliseconds: 120);

        if (!_isSeekingForLoop &&
            !inCooldown &&
            _currentPosition + lookahead >= end) {
          _isSeekingForLoop = true;
          _lastSeekAt = now;
          try {
            await _audioService.seek(_abStart!);
            await _audioService.resume();
          } finally {
            _isSeekingForLoop = false;
          }
        }

        // ① 単語ワンショットの終了判定（常に評価）
        if (_isWordPlaying && _wordPlayEnd != null) {
          if (_currentPosition + const Duration(milliseconds: 20) >=
              _wordPlayEnd!) {
            _wordStopTimer?.cancel();
            _isWordPlaying = false;
            _suppressABDuringWord = false;
            _wordPlayEnd = null;
            await _audioService.pause();
            // return; // 早期リターンしてもOK
          }
        }

        // ② ABループ（単語再生中は抑制）
        if (!_suppressABDuringWord &&
            _abState == ABRepeatState.ready &&
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
              await _audioService.pause(); // ★ ここで確実に停止
            } finally {
              _isSeekingForLoop = false;
            }
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

  Future<void> _playWordOnce(WordSegment w) async {
    final start = Duration(milliseconds: (w.start * 1000).round());
    final rawEnd = Duration(milliseconds: (w.end * 1000).round());
    final end = _paddedEnd(rawEnd);

    _suppressABDuringWord = true;
    try {
      await _audioService.playSegmentOnce(start: start, end: end);
    } finally {
      _suppressABDuringWord = false;
    }
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

  void _handleReset({bool alsoStopAudio = false}) {
    setState(() {
      _abStart = null;
      _abEnd = null;
      _aLabel = "--";
      _bLabel = "--";
      _abState = ABRepeatState.idle;
      _dim = false; // 暗転も解除
    });

    // 単語再生中フラグも解除
    _isWordPlaying = false;
    _suppressABDuringWord = false;
    _wordPlayEnd = null;

    if (alsoStopAudio) {
      _audioService.pause();
    }
  }

  @override
  void dispose() {
    _wordStopTimer?.cancel();
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
    final ds = 2;
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

                          // A/B 選択モード中：既存のAB設定ロジック
                          if (_abState == ABRepeatState.selectingA) {
                            setState(() {
                              _abStart = wStart;
                              _aLabel = _fmt(wStart);
                              _abEnd = null;
                              _bLabel = "--";
                              _abState = ABRepeatState.selectingB;
                              _dim = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('次にB地点にしたい単語をタップしてください')),
                            );
                            return;
                          }

                          if (_abState == ABRepeatState.selectingB) {
                            // 最短区間 200ms
                            if (wEnd <=
                                (_abStart ?? Duration.zero) +
                                    const Duration(milliseconds: 200)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('BはAより少し後にしてください（>=200ms）')),
                              );
                              return;
                            }
                            setState(() {
                              _abEnd = wEnd;
                              _bLabel = _fmt(wEnd);
                              _abState = ABRepeatState.ready;
                              _dim = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('AB区間を設定しました')),
                            );
                            return;
                          }

                          // ↑どちらでもない通常時：辞書ポップアップを表示
                          showWordMeaningSheet(
                            context,
                            word: word.word,
                            lookup: _dict.lookup,
                            onPlayOnce: () =>
                                _playWordOnce(word), // ★ ここを忘れてると未使用警告が出る
                          );
                        })
                    : Center(
                        child: Text(
                          "字幕を読み込み中…",
                          style: TextStyle(color: textColor),
                        ),
                      ),
              ),

              Container(
                width: double.infinity,
                height: 180,
                color: waveColor,
                child: Column(
                  children: [
                    // 🎵 波形
                    SizedBox(
                      height: 120,
                      child: (sampleFilePath != null)
                          ? SampleWaveformWidget(
                              filePath: sampleFilePath!,
                              height: 120,
                              progress: progress,
                              displaySeconds: ds,
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    // 🎤 カラオケ字幕バー（1行）
                    SizedBox(
                      height: 40,
                      child: CustomPaint(
                        size: const Size(double.infinity, 40),
                        painter: KaraokeSubtitlePainter(
                          wordSegments: _wordSegments,
                          currentMs: _currentPosition.inMilliseconds,
                          displaySeconds: ds, // 波形と必ず同じ
                          lingerMs: 220, // 過去残像
                          futureLookaheadWords: 3, // ★ 未来3語まで見せる
                          futureOpacities: const [0.8, 0.6, 0.4], // 濃さ（お好みで）
                          minW: 56,
                          minWActive: 96,
                        ),
                      ),
                    )
                  ],
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
