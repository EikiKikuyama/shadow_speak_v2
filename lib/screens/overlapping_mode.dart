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
import '../settings/settings_controller.dart';

// ★ マイクの“音拾ってるよ”用
import '../utils/mic_amplitude_service.dart';

class OverlappingMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;
  const OverlappingMode({super.key, required this.material});

  @override
  ConsumerState<OverlappingMode> createState() => _OverlappingModeState();
}

class _OverlappingModeState extends ConsumerState<OverlappingMode> {
  final AudioPlayerService _audioService = AudioPlayerService();

  // ===== ABリピート用 =====
  Duration? _abStart;
  Duration? _abEnd;
  ABRepeatState _abState = ABRepeatState.idle;
  bool _dim = false;
  String _aLabel = '--';
  String _bLabel = '--';

  bool _isSeekingForLoop = false;
  DateTime _lastSeekAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ===== 再生・字幕 =====
  String? sampleFilePath;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;

  List<SubtitleSegment> _subtitles = [];
  List<WordSegment> _wordSegments = [];
  SubtitleSegment? _currentSubtitle;
  StreamSubscription<Duration>? _positionSubscription;

  // ===== Mic LED（録音はしない／LEDだけ） =====
  final MicAmplitudeService _mic =
      MicAmplitudeService(sampleRate: 44100, hopMs: 5, gateDb: -46);
  bool _micActive = false; // start()/stop() の状態

  Future<void> _startMic() async {
    if (_micActive) return;
    await _mic.start();
    if (mounted) setState(() => _micActive = true);
  }

  Future<void> _stopMic() async {
    if (!_micActive) return;
    await _mic.stop();
    if (mounted) setState(() => _micActive = false);
  }

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

      // ===== ABループ（ListeningMode と同等の挙動） =====
      if (_abState == ABRepeatState.ready &&
          _abStart != null &&
          _abEnd != null) {
        const lookahead = Duration(milliseconds: 40);
        final now = DateTime.now();
        final inCooldown =
            now.difference(_lastSeekAt) < const Duration(milliseconds: 120);

        if (!_isSeekingForLoop &&
            !inCooldown &&
            _currentPosition + lookahead >= _abEnd!) {
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
    setState(() => sampleFilePath = path);
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
    });
  }

  // ===== Controls =====
  Future<void> _togglePlayPause(bool isPlaying) async {
    if (sampleFilePath == null) return;
    await _audioService.setSpeed(_currentSpeed);
    if (isPlaying) {
      await _audioService.pause();
      await _stopMic(); // 一時停止でLEDも止める
    } else {
      await _startMic();
      await _audioService.resume();
    }
  }

  Future<void> _reset() async {
    await _audioService.reset();
    await _stopMic();
    if (sampleFilePath != null) {
      await _audioService.prepareLocalFile(sampleFilePath!, _currentSpeed);
    }
    if (!mounted) return;
    setState(() {
      _currentPosition = Duration.zero;
      _abStart = null;
      _abEnd = null;
      _aLabel = '--';
      _bLabel = '--';
      _abState = ABRepeatState.idle;
      _dim = false;
    });
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

  void _handleResetAB({bool alsoStopAudio = false}) {
    setState(() {
      _abStart = null;
      _abEnd = null;
      _aLabel = '--';
      _bLabel = '--';
      _abState = ABRepeatState.idle;
      _dim = false;
    });
    if (alsoStopAudio) {
      _audioService.pause();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stopMic();
    _mic.dispose();
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
    final subtitleHeight = screenHeight * 0.30;

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    const ds = 2; // 表示窓（秒）— Listening と合わせる

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '🗣 オーバーラッピングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
        actions: [],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ===== 字幕（全体） =====
              Container(
                height: subtitleHeight,
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _subtitles.isNotEmpty
                    ? SubtitleDisplay(
                        currentTime: _currentPosition,
                        allSubtitles: _subtitles,
                        highlightColor: Colors.blue,
                        defaultColor: textColor,
                        abState: _abState,
                        abStart: _abStart,
                        abEnd: _abEnd,
                        selectedA: _abStart,
                        selectedB: _abEnd,
                        onSelectSubtitle: (start, end) {
                          // セグメントタップ時に A/B を直接入れてもOK（任意）
                        },
                        onWordTap: (word) {
                          final wStart = Duration(
                              milliseconds: (word.start * 1000).toInt());
                          final wEnd =
                              Duration(milliseconds: (word.end * 1000).toInt());

                          // A/B 選択モード中のみ処理（辞書は出さない）
                          if (_abState == ABRepeatState.selectingA) {
                            setState(() {
                              _abStart = wStart;
                              _aLabel = _fmt(wStart);
                              _abEnd = null;
                              _bLabel = '--';
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
                          // 通常タップ時は何もしない（辞書は出さない）
                        },
                      )
                    : Center(
                        child: Text(
                          '字幕を読み込み中…',
                          style: TextStyle(color: textColor),
                        ),
                      ),
              ),

              // ===== 波形 + カラオケ字幕バー =====
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
                          ? Stack(
                              children: [
                                SampleWaveformWidget(
                                  filePath: sampleFilePath!,
                                  height: 120,
                                  progress: progress,
                                  displaySeconds: ds,
                                ),
                                // ★ Mic LED（右上）：“音拾ってるよ”
                                // 置き換え（OverlappingMode の Positioned 右上）
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: StreamBuilder<double>(
                                    stream: _mic.amplitudeStream,
                                    initialData: 0.0,
                                    builder: (context, snap) {
                                      final amp = (snap.data ?? 0.0);
                                      // ちょい平滑（EMA）
                                      // ↓ 簡易スムージングを State に持たせたくなければ static でもOK
                                      double eased = amp;
                                      // 見た目用スケール
                                      final level =
                                          (eased * 1.35).clamp(0.0, 1.0);
                                      final size =
                                          10.0 + 8.0 * level; // 10~18px
                                      final active = level > 0.06;

                                      final color = active
                                          ? Color.lerp(Colors.orange,
                                              Colors.redAccent, level)!
                                          : Colors.black26;

                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 90),
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                          boxShadow: active
                                              ? [
                                                  BoxShadow(
                                                    // ignore: deprecated_member_use
                                                    color: color.withOpacity(
                                                        0.35 + 0.25 * level),
                                                    blurRadius: 12 + 8 * level,
                                                    spreadRadius:
                                                        1.5 + 1.5 * level,
                                                  ),
                                                ]
                                              : const [],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    // 🎤 カラオケ字幕（1行）
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

              // ===== 下部コントロール =====
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
                    const SizedBox(height: 8),
                    ABRepeatControls(
                      aTime: _aLabel,
                      bTime: _bLabel,
                      onSetA: _handleSetA,
                      onSetB: _handleSetB,
                      onReset: () => _handleResetAB(alsoStopAudio: false),
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

          // ===== A/B選択中の暗転 =====
          if (_dim)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                // ignore: deprecated_member_use
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
        ],
      ),
    );
  }
}
