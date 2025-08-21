import 'dart:async';
import 'package:flutter/material.dart';
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
  // 再生
  final AudioPlayerService _audioService = AudioPlayerService();
  String? sampleFilePath;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;

  // 字幕
  List<SubtitleSegment> _subtitles = [];
  List<WordSegment> _wordSegments = [];
  SubtitleSegment? _currentSubtitle;

  // 全文↔日本語訳トグル
  bool _showJp = false;

  // ABリピート
  Duration? _abStart;
  Duration? _abEnd;
  ABRepeatState _abState = ABRepeatState.idle;
  bool _dim = false; // A/B選択ガイダンスの半透明オーバレイ
  String _aLabel = '--';
  String _bLabel = '--';

  // 単語ポップアップ辞書 & ワンショット再生
  final _dict = SimpleDictionary();
  static const int _kTailPadMs = 150; // 単語ワンショットの余韻
  Duration _paddedEnd(Duration end) {
    final total = _audioService.totalDuration;
    final padded = end + const Duration(milliseconds: _kTailPadMs);
    if (total == null) return padded;
    return padded <= total ? padded : total;
  }

  @override
  void initState() {
    super.initState();
    _dict.init();
    _loadSampleAudio();
    _loadSubtitle();

    _positionSubscription = _audioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      final current = getCurrentSubtitle(_subtitles, pos);
      if (current != _currentSubtitle) {
        setState(() => _currentSubtitle = current);
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioService.stop();
    _audioService.dispose();
    super.dispose();
  }

  // ====== ロード系 ======
  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    await _audioService.prepareLocalFile(path, _currentSpeed);
    setState(() => sampleFilePath = path);
  }

  Future<void> _loadSubtitle() async {
    final key = widget.material.scriptPath
        .replaceFirst('assets/subtitles/', '')
        .replaceAll('.json', '')
        .replaceAll('.txt', '');
    final subs = await loadSubtitles(key);
    final words = await loadWordSegments(key);
    if (!mounted) return;
    setState(() {
      _subtitles = subs;
      _wordSegments = words;
    });
  }

  // ====== 再生制御 ======
  Future<void> _togglePlayPause(bool isPlaying) async {
    if (sampleFilePath == null) return;
    await _audioService.setSpeed(_currentSpeed);
    if (isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.resume();
    }
  }

  Future<void> _reset() => _audioService.reset();

  // ====== 単語ワンショット ======
  Future<void> _playWordOnce(WordSegment w) async {
    final start = Duration(milliseconds: (w.start * 1000).round());
    final rawEnd = Duration(milliseconds: (w.end * 1000).round());
    final end = _paddedEnd(rawEnd);
    await _audioService.playSegmentOnce(start: start, end: end);
  }

  // ====== ABリピート UI ハンドラ ======
  String _fmt(Duration d) {
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final m = d.inMinutes.toString();
    return '$m:$s.$ms';
  }

  Future<void> _handleSetA() async {
    setState(() {
      _showJp = false; // A/B選択は英語で
      _abState = ABRepeatState.selectingA;
      _dim = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A地点にしたい本文をタップしてください')),
      );
    }
  }

  Future<void> _handleSetB() async {
    setState(() {
      _showJp = false; // Bも同様
      _abState = (_abStart == null)
          ? ABRepeatState.selectingA
          : ABRepeatState.selectingB;
      _dim = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_abStart == null
              ? '先にA地点を選んでください（本文をタップ）'
              : 'B地点にしたい本文をタップしてください'),
        ),
      );
    }
  }

  void _handleReset({bool alsoStopAudio = false}) {
    setState(() {
      _abStart = null;
      _abEnd = null;
      _aLabel = '--';
      _bLabel = '--';
      _abState = ABRepeatState.idle;
      _dim = false;
    });
    _audioService.stopABLoop();
    if (alsoStopAudio) _audioService.pause();
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsControllerProvider).isDarkMode;

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
    const int ds = 2;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '🎧 リスニングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _LangToggle(
              showJp: _showJp,
              onChanged: (v) => setState(() => _showJp = v),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ===== 上：全文エリア =====
              Container(
                height: subtitleHeight,
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _subtitles.isNotEmpty
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: _showJp
                                ? _buildFullTranslation(textColor)
                                : SubtitleDisplay(
                                    currentTime: _currentPosition,
                                    allSubtitles: _subtitles,
                                    highlightColor: Colors.blue,
                                    defaultColor: textColor,
                                    abState: _abState,
                                    abStart: _abStart,
                                    abEnd: _abEnd,
                                    selectedA: _abStart,
                                    selectedB: _abEnd,
                                    onSelectSubtitle: (s, e) {},
                                    onWordTap: (word) async {
                                      final wStart = Duration(
                                          milliseconds:
                                              (word.start * 1000).toInt());
                                      final wEnd = Duration(
                                          milliseconds:
                                              (word.end * 1000).toInt());

                                      // AB選択モード
                                      if (_abState ==
                                          ABRepeatState.selectingA) {
                                        setState(() {
                                          _abStart = wStart;
                                          _aLabel = _fmt(wStart);
                                          _abEnd = null;
                                          _bLabel = '--';
                                          _abState = ABRepeatState.selectingB;
                                          _dim = true;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  '次にB地点にしたい単語をタップしてください')),
                                        );
                                        return;
                                      }

                                      if (_abState ==
                                          ABRepeatState.selectingB) {
                                        // 最短幅
                                        if (wEnd <=
                                            (_abStart ?? Duration.zero) +
                                                const Duration(
                                                    milliseconds: 200)) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'BはAより少し後にしてください（>=200ms）')),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          _abEnd = wEnd;
                                          _bLabel = _fmt(wEnd);
                                          _abState = ABRepeatState.ready;
                                          _dim = false;
                                        });
                                        // ここでABループ開始
                                        if (_abStart != null &&
                                            _abEnd != null) {
                                          await _audioService.playABLoop(
                                            a: _abStart!,
                                            b: _abEnd!,
                                          );
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('AB区間を設定しました')),
                                        );
                                        return;
                                      }

                                      // 通常：辞書ポップアップ（+単語ワンショット）
                                      showWordMeaningSheet(
                                        context,
                                        word: word.word,
                                        lookup: _dict.lookup,
                                        onPlayOnce: () => _playWordOnce(word),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text('字幕を読み込み中…',
                            style: TextStyle(color: textColor))),
              ),

              // ===== 中：波形＋カラオケバー =====
              Container(
                width: double.infinity,
                height: 180,
                color: waveColor,
                child: Column(
                  children: [
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
                    SizedBox(
                      height: 40,
                      child: CustomPaint(
                        size: const Size(double.infinity, 40),
                        painter: KaraokeSubtitlePainter(
                          wordSegments: _wordSegments,
                          currentMs: _currentPosition.inMilliseconds,
                          displaySeconds: ds,
                          lingerMs: 220,
                          futureLookaheadWords: 3,
                          futureOpacities: const [0.8, 0.6, 0.4],
                          minW: 56,
                          minWActive: 96,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== 下：コントロール群 =====
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    if (total != null && total.inMilliseconds > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Slider(
                          value: _currentPosition.inMilliseconds
                              .toDouble()
                              .clamp(0, total.inMilliseconds.toDouble()),
                          min: 0,
                          max: total.inMilliseconds.toDouble(),
                          activeColor: sliderActiveColor,
                          inactiveColor: sliderInactiveColor,
                          onChanged: (v) => setState(() {
                            _currentPosition =
                                Duration(milliseconds: v.toInt());
                          }),
                          onChangeEnd: (v) => _audioService
                              .seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                    StreamBuilder<bool>(
                      stream: _audioService.isPlayingStream,
                      initialData: false,
                      builder: (context, snap) {
                        final isPlaying = snap.data ?? false;
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
                    ABRepeatControls(
                      aTime: _aLabel,
                      bTime: _bLabel,
                      onSetA: _handleSetA,
                      onSetB: _handleSetB,
                      onReset: () => _handleReset(alsoStopAudio: false),
                    ),
                    const SizedBox(height: 12),
                    SpeedSelector(
                      currentSpeed: _currentSpeed,
                      onSpeedSelected: (s) {
                        setState(() => _currentSpeed = s);
                        _audioService.setSpeed(s);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_dim)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
        ],
      ),
    );
  }

  // 全訳ビュー
  Widget _buildFullTranslation(Color color) {
    final lines = _subtitles
        .map((s) => (s.translation.isNotEmpty ? s.translation : s.text))
        .toList();
    final body = lines.join('\n\n');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SelectableText(
        body,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 18,
          height: 1.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 右上の EN/JP ピル・トグル
class _LangToggle extends StatelessWidget {
  final bool showJp;
  final ValueChanged<bool> onChanged;
  const _LangToggle({required this.showJp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);
    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _pill(label: 'EN', selected: !showJp, onTap: () => onChanged(false)),
        const SizedBox(width: 4),
        _pill(label: 'JP', selected: showJp, onTap: () => onChanged(true)),
      ]),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurpleAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
