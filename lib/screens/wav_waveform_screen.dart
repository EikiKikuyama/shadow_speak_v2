// lib/screens/wav_waveform_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_model.dart';
import '../services/audio_player_service.dart';
import '../screens/ai_scoring_screen.dart';
import '../services/subtitle_loader.dart';
import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart';

import '../audio/waveform_pipeline.dart';
import '../audio/wav_loader.dart';
import '../settings/latency.dart';
import '../widgets/series_waveform_widget.dart';
import '../utils/wav_utils.dart';
import 'dart:io';

class WavWaveformScreen extends ConsumerStatefulWidget {
  final String wavFilePath; // あなたの録音WAV
  final PracticeMaterial material; // 見本の素材

  const WavWaveformScreen({
    super.key,
    required this.wavFilePath,
    required this.material,
  });

  @override
  ConsumerState<WavWaveformScreen> createState() => _WavWaveformScreenState();
}

class _WavWaveformScreenState extends ConsumerState<WavWaveformScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();

  bool _isPlaying = false;
  String subtitleText = '';

  // 0..1 の 200fps シリーズ
  List<double> _sampleSeries = []; // 見本
  List<double> _recordedSeries = []; // あなた
  int _sampleRate = 44100;

  double _currentProgress = 0.0; // 0..1
  StreamSubscription<Duration>? _posSub;

  // 後で STT の結果を入れる場所（今は空でOK）
  String? _userSttText;

  @override
  void initState() {
    super.initState();
    _prepareWaveforms();
    _loadSubtitle();

    _posSub = _audioService.positionStream.listen((pos) {
      if (!mounted || _audioService.totalDuration == null) return;
      final total = _audioService.totalDuration!.inMilliseconds;
      final current = pos.inMilliseconds;
      setState(() {
        _currentProgress = total > 0 ? current / total : 0.0;
      });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _prepareWaveforms() async {
    // 見本 / 録音 WAV を float モノラルで取得
    final sample = await loadWavAssetAsMonoFloat(widget.material.audioPath);
    final recorded = await loadWavAsMonoFloat(widget.wavFilePath);

    _sampleRate = sample.sampleRate;

    final lagMs = ref.read(lagMsProvider);
    final cfg = WaveformPipelineConfig(
      alpha: 0.18,
      rmsWinMs: 10,
      hopMs: 5, // → 200fps
      lagMs: lagMs,
    );

    // 0..1 の 200fps 系列に変換
    var sampleSeries = WaveformPipeline.process(
      raw: sample.samples,
      sampleRate: _sampleRate,
      cfg: cfg,
    );
    var recordedSeries = WaveformPipeline.process(
      raw: recorded.samples,
      sampleRate: _sampleRate,
      cfg: cfg,
    );

    // ノイズゲート等の仕上げ
    sampleSeries =
        applyNoiseGate(sampleSeries, openDb: -38, closeDb: -52, holdMs: 120);
    recordedSeries =
        applyNoiseGate(recordedSeries, openDb: -38, closeDb: -52, holdMs: 120);

    sampleSeries = squelchTinyIslands(sampleSeries, minOnMs: 100, level: 0.02);
    recordedSeries =
        squelchTinyIslands(recordedSeries, minOnMs: 100, level: 0.02);

    sampleSeries = subtractGlobalFloor(sampleSeries, q: 0.12, margin: 1.10);
    recordedSeries = subtractGlobalFloor(recordedSeries, q: 0.12, margin: 1.10);

    sampleSeries = autoZeroFloor(sampleSeries, quantile: 0.985, margin: 1.05);
    recordedSeries =
        autoZeroFloor(recordedSeries, quantile: 0.985, margin: 1.05);

    debugQuietStats('recorded AFTER ', recordedSeries);

    if (!mounted) return;
    setState(() {
      _sampleSeries = sampleSeries;
      _recordedSeries = recordedSeries;
    });
  }

  // “無音床”を自動で0固定に寄せる
  List<double> autoZeroFloor(
    List<double> s, {
    double maxSilence = 0.06,
    double quantile = 0.98,
    double margin = 1.15,
  }) {
    final low = s.where((v) => v >= 0 && v <= maxSilence).toList()..sort();
    if (low.isEmpty) return s;
    final idx = (low.length * quantile).floor().clamp(0, low.length - 1);
    final floor = (low[idx] * margin).clamp(0.0, 1.0);
    return s.map((v) => (v < floor) ? 0.0 : v).toList();
  }

  Future<void> _loadSubtitle() async {
    try {
      final filename = widget.material.scriptPath
          .replaceFirst('assets/subtitles/', '')
          .replaceAll('.json', '')
          .replaceAll('.txt', '');
      final data = await loadSubtitles(filename);
      if (!mounted) return;
      setState(() {
        subtitleText = data.map((s) => s.text).join('\n');
      });
    } catch (e) {
      debugPrint('❌ 字幕読み込み失敗: $e');
      setState(() => subtitleText = '字幕の読み込みに失敗しました。');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _play() async {
    if (_isPlaying) return; // 二重再生防止
    final path = widget.wavFilePath;

    try {
      final f = File(path);
      if (!f.existsSync()) {
        _showSnack('録音ファイルが見つかりません');
        return;
      }
      if (f.lengthSync() < 1200) {
        _showSnack('録音が短すぎるか壊れている可能性があります');
        return;
      }

      setState(() => _isPlaying = true);
      await _audioService.prepareAndPlayLocalFile(path, 1.0);
    } catch (e) {
      debugPrint('play error: $e');
      _showSnack('再生に失敗しました。もう一度試すか録音し直してください');
      // 事故復旧：内部状態を初期化
      try {
        await _audioService.reset();
      } catch (_) {}
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _pause() async {
    setState(() => _isPlaying = false);
    await _audioService.pause();
  }

  Future<void> _reset() async {
    setState(() => _isPlaying = false);
    await _audioService.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsControllerProvider).isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF001f3f) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final waveformBackground1 = isDark ? Colors.white : Colors.black;
    final waveformBackground2 = isDark ? Colors.black : Colors.grey[200]!;

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - MediaQuery.of(context).padding.top - 64;
    final waveformHeight = availableHeight * 0.18;
    final subtitleHeight = availableHeight * 0.25;

    Widget buildWaveformContainer({
      required Widget child,
      required Color background,
    }) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: waveformHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '自己チェックシート',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
        actions: [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('あなたの音声の波形',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              buildWaveformContainer(
                background: waveformBackground1,
                child: _recordedSeries.isEmpty
                    ? Center(child: CircularProgressIndicator(color: textColor))
                    : SeriesWaveformWidget(
                        series: _recordedSeries,
                        progress: _currentProgress,
                        verticalPadding: 12.0,
                      ),
              ),
              const SizedBox(height: 24),
              Text('見本の音声の波形',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              buildWaveformContainer(
                background: waveformBackground2,
                child: _sampleSeries.isEmpty
                    ? Center(child: CircularProgressIndicator(color: textColor))
                    : SeriesWaveformWidget(
                        series: _sampleSeries,
                        progress: _currentProgress,
                        verticalPadding: 12.0,
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                        color: textColor, size: 36),
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(Icons.replay, color: textColor, size: 32),
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: subtitleHeight,
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // ====== AI採点へ ======
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (_sampleSeries.isEmpty || _recordedSeries.isEmpty)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AiScoringScreen(
                                referenceText: subtitleText, // 正解台本
                                transcribedText:
                                    _userSttText ?? '', // ← Whisper 等の結果
                                sampleSeries: _sampleSeries, // 見本 0..1 200fps
                                userSeries: _recordedSeries, // あなた 0..1 200fps
                                userWavPath: widget.wavFilePath, // ★必須
                              ),
                            ),
                          );
                        },
                  child: Text(
                    'AI採点モードへ →',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
