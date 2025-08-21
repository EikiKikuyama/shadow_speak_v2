// lib/screens/recording_only_mode.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';

import '../settings/settings_controller.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/subtitle_display.dart'; // 全文ハイライト表示
import '../widgets/series_waveform_widget.dart'; // 200fps の系列を描画
import '../painters/line_wave_painter.dart'; // KaraokeSubtitlePainter 内で使用
import '../screens/wav_waveform_screen.dart';

// 波形生成
import '../audio/wav_loader.dart';
import '../audio/waveform_pipeline.dart';

class RecordingOnlyMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;
  const RecordingOnlyMode({super.key, required this.material});

  @override
  ConsumerState<RecordingOnlyMode> createState() => _RecordingOnlyModeState();
}

class _RecordingOnlyModeState extends ConsumerState<RecordingOnlyMode> {
  // ====== 定数（字幕/波形の窓幅など） ======
  static const int kDisplaySeconds = 2; // 波形とカラオケ1行の可視窓幅（秒）
  static const int kLingerMs = 120; // 過去残像（0〜150msで調整）
  static const int kLeadMs = -80; // 字幕を少し前に出す微調整（-120〜+120ms）

  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _audio = AudioPlayerService();

  // 字幕データ
  List<SubtitleSegment> _subtitles = [];
  List<WordSegment> _wordSegments = [];

  // 進行管理
  bool _isRecording = false;
  int? _countdown; // 3→2→1 オーバーレイ
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // 波形（200fps = 5ms hop）
  List<double> _sampleSeries = [];
  List<double> _visualSeries = []; // 倍速用に伸縮させた見た目
  int _sampleDurationMs = 0; // series.length * 5
  int get _totalMs => _sampleDurationMs > 0
      ? _sampleDurationMs
      : widget.material.durationSec * 1000;

  // カーソル進行（0..1）
  double _waveProgress = 0.0;
  Timer? _progressTimer;
  DateTime? _progressStart;

  // 倍速（見た目の伸縮＋進行速度に反映）
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
    _prepareSampleWaveform();
  }

  // ---- データ読み込み ----
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

  Future<void> _prepareSampleWaveform() async {
    final wav = await loadWavAssetAsMonoFloat(widget.material.audioPath);
    const cfg =
        WaveformPipelineConfig(alpha: 0.18, rmsWinMs: 10, hopMs: 5, lagMs: 0);
    final series = WaveformPipeline.process(
      raw: wav.samples,
      sampleRate: wav.sampleRate,
      cfg: cfg,
    );
    setState(() {
      _sampleSeries = series;
      _sampleDurationMs = series.length * 5; // 200fps → 1index=5ms
      _rebuildVisualSeries();
    });
  }

  // ---- 波形リサンプリング（横方向の伸縮） ----
  void _rebuildVisualSeries() {
    if (_sampleSeries.isEmpty) {
      _visualSeries = const [];
    } else {
      final newLen =
          (_sampleSeries.length / _playbackRate).clamp(8, 200000).round();
      _visualSeries = _resample1D(_sampleSeries, newLen);
    }
    setState(() {}); // 再描画
  }

  List<double> _resample1D(List<double> s, int newLen) {
    if (s.isEmpty || newLen <= 0) return const [];
    if (newLen == 1) return [s.first];
    final out = List<double>.filled(newLen, 0.0);
    final last = s.length - 1;
    for (int i = 0; i < newLen; i++) {
      final t = i * last / (newLen - 1);
      final j0 = t.floor();
      final j1 = (j0 + 1 <= last) ? j0 + 1 : last;
      final a = t - j0;
      out[i] = s[j0] * (1 - a) + s[j1] * a;
    }
    return out;
  }

  void _changePlaybackRate(double rate) {
    if (_playbackRate == rate) return;

    // いまの位置（ms）を保持したまま倍速切り替え
    final currentMs = (_waveProgress * _totalMs).round();

    _playbackRate = rate;
    _rebuildVisualSeries();

    if (_isRecording && _progressStart != null) {
      final now = DateTime.now();
      final newElapsedMs = (currentMs / _playbackRate).round();
      _progressStart = now.subtract(Duration(milliseconds: newElapsedMs));
    } else {
      setState(() {}); // 非録音時も即反映
    }
  }

  // ---- 録音制御 ----
  Future<void> _startCountdownAndRecord() async {
    if (_isRecording || _countdown != null) return;
    setState(() => _countdown = 3);

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown = i - 1);
    }

    if (!mounted) return;
    setState(() => _countdown = null);
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    // 進行リセット
    setState(() {
      _isRecording = true;
      _waveProgress = 0.0;
      _recordingSeconds = 0;
    });

    // 秒数表示用
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingSeconds++);
    });

    // カーソル進行（倍速反映）
    _progressStart = DateTime.now();
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_isRecording || _progressStart == null) return;
      final elapsed = DateTime.now().difference(_progressStart!).inMilliseconds;
      final adjusted = (elapsed * _playbackRate).round();
      final p = (adjusted / _totalMs).clamp(0.0, 1.0);
      setState(() => _waveProgress = p);
      if (p >= 1.0) _stopRecording(); // 自動停止
    });

    // ファイルへ録音開始
    final savePath = await _recorder.getSavePath(
        level: widget.material.level, title: widget.material.title);
    await _recorder.startRecording(
      path: savePath,
      level: widget.material.level,
      title: widget.material.title,
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stopRecording();

    _recordingTimer?.cancel();
    _recordingTimer = null;

    _progressTimer?.cancel();
    _progressTimer = null;
    _progressStart = null;

    setState(() {
      _isRecording = false;
      _waveProgress = 0.0;
    });

    if (!mounted) return;
    if (path != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WavWaveformScreen(
            wavFilePath: path,
            material: widget.material,
          ),
        ),
      );
    }
  }

  Future<void> _reset() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    _progressTimer?.cancel();
    _progressTimer = null;
    _progressStart = null;

    setState(() {
      _isRecording = false;
      _countdown = null;
      _waveProgress = 0.0;
      _recordingSeconds = 0;
    });

    await _audio.stop(); // 念のため無音化
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _progressTimer?.cancel();
    _recorder.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsControllerProvider).isDarkMode;

    final backgroundColor =
        isDark ? const Color(0xFF001F3F) : const Color(0xFFF4F1FA);
    final textColor = isDark ? Colors.white : Colors.black;
    final waveBgColor = isDark ? Colors.white10 : Colors.grey[200]!;

    final screenH = MediaQuery.of(context).size.height;
    final subtitleH = screenH * 0.32;
    final positionMs = (_totalMs > 0) ? (_waveProgress * _totalMs).round() : 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '🎙️ レコーディングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
        actions: [],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ① 上：全文（独立スクロール / 1語ずつハイライト）
              SizedBox(
                height: subtitleH,
                width: double.infinity,
                child: _subtitles.isEmpty
                    ? Center(
                        child: Text('字幕を読み込み中…',
                            style: TextStyle(color: textColor)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: SubtitleDisplay(
                          currentTime: Duration(milliseconds: positionMs),
                          allSubtitles: _subtitles,
                          highlightColor: Colors.blue,
                          defaultColor: textColor,
                          // AB は使わないので idle/null を渡す
                          abState: ABRepeatState.idle,
                          abStart: null,
                          abEnd: null,
                          selectedA: null,
                          selectedB: null,
                          onSelectSubtitle: null,
                          onWordTap: null,
                        ),
                      ),
              ),

              // ② 中：見本波形 + カラオケ1行
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 180,
                decoration: BoxDecoration(
                  color: waveBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 波形（速度で横方向に伸縮）
                    Expanded(
                      child: _visualSeries.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : SeriesWaveformWidget(
                              series: _visualSeries, // 0..1 正規化系列
                              progress: _waveProgress, // 0..1 カーソル
                              verticalPadding: 12.0,
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: CustomPaint(
                        size: const Size(double.infinity, 40),
                        painter: KaraokeSubtitlePainter(
                          wordSegments: _wordSegments, // 秒
                          currentMs: positionMs + kLeadMs, // ms（微調整）
                          displaySeconds: kDisplaySeconds, // 波形と必ず同じ窓幅
                          lingerMs: kLingerMs, // 過去残像
                          futureLookaheadWords: 3, // 未来3語
                          futureOpacities: const [0.8, 0.6, 0.4],
                          minW: 56.0,
                          minWActive: 96.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text('上の文章を声に出して録音してみよう',
                  style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),

              // ③ 速度チップ
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [0.75, 1.0, 1.25, 1.5].map((rate) {
                    final selected = (_playbackRate == rate);
                    return ChoiceChip(
                      label: Text(
                        '${rate}x',
                        style: TextStyle(
                            color: selected ? Colors.white : textColor),
                      ),
                      selected: selected,
                      onSelected: (_) => _changePlaybackRate(rate),
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey.shade300,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // ④ 録音操作
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _isRecording
                        ? _stopRecording()
                        : _startCountdownAndRecord(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 4),
                        color: _isRecording ? Colors.red : Colors.transparent,
                      ),
                      child: Icon(Icons.mic, color: textColor, size: 40),
                    ),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: Icon(Icons.restart_alt, size: 36, color: textColor),
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),

          // ⑤ カウントダウン・オーバーレイ
          if (_countdown != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                alignment: Alignment.center,
                child: Text(
                  _countdown! > 0 ? '${_countdown!}' : 'Start!',
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
