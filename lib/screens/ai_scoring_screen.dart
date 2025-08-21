// lib/screens/ai_scoring_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptic
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadow_speak_v2/settings/settings_controller.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';
import 'package:shadow_speak_v2/widgets/collapsible_card.dart';
import 'package:shadow_speak_v2/widgets/wave_compare_card.dart';

import 'package:shadow_speak_v2/utils/scoring_utils.dart'; // buildDiffSpans / feedback など
import 'package:shadow_speak_v2/services/whisper_api_service.dart';
import 'package:shadow_speak_v2/models/stt_result.dart';

class AiScoringScreen extends ConsumerStatefulWidget {
  final String referenceText; // 見本英文
  final String transcribedText; // 初期のSTTテキスト（空でも可）
  final List<double> sampleSeries; // 見本 0..1（200fps想定）
  final List<double> userSeries; // あなた 0..1（200fps想定）
  final double? prosodyScore; // 渡されなければ画面で算出
  final double? whisperScore; // 渡されなければ画面で算出
  final String? userWavPath; // 録音WAVのフルパス（STT/キャッシュに使用）

  const AiScoringScreen({
    super.key,
    required this.referenceText,
    required this.transcribedText,
    required this.sampleSeries,
    required this.userSeries,
    this.prosodyScore,
    this.whisperScore,
    this.userWavPath,
  });

  @override
  ConsumerState<AiScoringScreen> createState() => _AiScoringScreenState();
}

class _AiScoringScreenState extends ConsumerState<AiScoringScreen> {
  // --- services ---
  final WhisperApiService _whisper = WhisperApiService();

  // --- state ---
  late double _prosodyScore;
  late double _whisperScore;
  bool _isScoring = false;
  bool _autoRunDone = false;
  bool _celebrate = false;

  final TextEditingController _recognizedTextController =
      TextEditingController();

  double get _overall =>
      ((_prosodyScore + _whisperScore) / 2).clamp(0, 100).toDouble();

  String get _overallLabel {
    if (_overall >= 90) return 'Excellent';
    if (_overall >= 80) return 'Great';
    if (_overall >= 70) return 'Good';
    return 'Keep Going';
  }

  @override
  void initState() {
    super.initState();

    _prosodyScore = widget.prosodyScore ??
        prosodyScoreFromSeries(widget.sampleSeries, widget.userSeries);

    _recognizedTextController.text = widget.transcribedText;

    _whisperScore = widget.whisperScore ??
        wordAccuracyScore(widget.referenceText, widget.transcribedText);

    // 入場：まずキャッシュ表示 → 無ければSTT
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_autoRunDone) return;
      _autoRunDone = true;

      final shownFromCache = await _loadSttCacheIfAny();
      if (!shownFromCache &&
          (widget.userWavPath != null && widget.userWavPath!.isNotEmpty)) {
        await _runSttAndScore();
      }
    });
  }

  @override
  void dispose() {
    _recognizedTextController.dispose();
    super.dispose();
  }

  // =========================
  // STTキャッシュ & スコア保存
  // =========================
  String? get _sttCachePath {
    final p = widget.userWavPath;
    if (p == null || p.isEmpty) return null;
    return '$p.stt.json';
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
      .replaceAll(RegExp(r"\s+"), ' ')
      .trim();

  Future<bool> _loadSttCacheIfAny() async {
    final cp = _sttCachePath;
    if (cp == null) return false;
    try {
      final f = File(cp);
      if (!await f.exists()) return false;

      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final cachedText = (j['text'] ?? '') as String;
      if (cachedText.isEmpty) return false;

      // refKeyが違ってもまずは即表示＆現行referenceで再計算（高速表示）
      _recognizedTextController.text = cachedText;
      _whisperScore = wordAccuracyScore(widget.referenceText, cachedText);

      if (mounted) setState(() {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSttCache({
    required String text,
    required double whisperScore,
  }) async {
    final cp = _sttCachePath;
    if (cp == null) return;
    try {
      final j = {
        'ver': 1,
        'refKey': _norm(widget.referenceText).hashCode,
        'text': text,
        'whisperScore': whisperScore,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await File(cp).writeAsString(jsonEncode(j));
    } catch (_) {}
  }

  Future<void> _saveScoreJson() async {
    final p = widget.userWavPath;
    if (p == null || p.isEmpty) return;
    final sp = '$p.score.json';
    final data = {
      'ver': 1,
      'overall': _overall,
      'prosody': _prosodyScore,
      'whisper': _whisperScore,
      'updatedAt': DateTime.now().toIso8601String(),
      'titleGuess': _guessTitleFromPath(p),
      'levelGuess': _guessLevelFromPath(p),
    };
    try {
      await File(sp).writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  String _guessTitleFromPath(String path) {
    final base = path.split('/').last.replaceAll('.wav', '');
    final parts = base.split('__');
    if (parts.length >= 2) return parts[1].replaceAll('-', ' ').trim();
    return '';
  }

  String _guessLevelFromPath(String path) {
    final base = path.split('/').last.replaceAll('.wav', '');
    final parts = base.split('__');
    if (parts.isEmpty) return '';
    switch (parts[0].toLowerCase()) {
      case 'starter':
        return 'Starter（〜50語）';
      case 'basic':
        return 'Basic（〜80語）';
      case 'intermediate':
        return 'Intermediate（〜100語）';
      case 'upper':
        return 'Upper（〜130語）';
      case 'advanced':
        return 'Advanced（〜150語）';
      default:
        return '';
    }
  }

  // =========================
  // STT → 採点
  // =========================
  Future<void> _runSttAndScore() async {
    final path = widget.userWavPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      _showSnack('録音ファイルが見つかりません。もう一度お試しください。');
      return;
    }

    if (!mounted) return;
    setState(() => _isScoring = true);

    try {
      final SttResult? stt = await _whisper
          .transcribeAudio(path)
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      if (stt == null || stt.fullText.isEmpty) {
        _showSnack('分析に失敗しました（結果が空）');
        return;
      }

      _recognizedTextController.text = stt.fullText;
      _whisperScore = wordAccuracyScore(widget.referenceText, stt.fullText);

      await _saveSttCache(text: stt.fullText, whisperScore: _whisperScore);
      await _saveScoreJson();

      setState(() {});
      _maybeCelebrate();
    } catch (e) {
      if (mounted) {
        _showSnack('分析に失敗しました。通信や録音を確認して、もう一度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _isScoring = false);
    }
  }

  // =========================
  // UI helpers
  // =========================
  void _showSnack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _maybeCelebrate() async {
    if (_overall >= 90 && !_celebrate) {
      setState(() => _celebrate = true);
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) setState(() => _celebrate = false);
    }
  }

  bool _approxEquals(String a, String b) => _norm(a) == _norm(b);

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsControllerProvider).isDarkMode;
    final bg = isDark ? const Color(0xFF08254D) : const Color(0xFFF3F0FA);
    final text = isDark ? Colors.white : Colors.black87;
    final card = Colors.white;

    // 比較欄
    final refText = widget.referenceText;
    final hypText = _recognizedTextController.text;
    late final Widget comparisonChild;

    if (hypText.trim().isEmpty) {
      comparisonChild = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('まだ結果がありません。自動分析を待つか、右上の「もう一度分析」を押してください。',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      );
    } else if (_approxEquals(refText, hypText)) {
      comparisonChild = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93E1B5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(children: [
              Icon(Icons.check_circle, color: Color(0xFF157347)),
              SizedBox(width: 8),
              Text('完全一致！差分は見つかりませんでした',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF157347))),
            ]),
            SizedBox(height: 6),
            Text('（大小文字／句読点／余分な空白は無視して判定）',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );
    } else {
      comparisonChild = RichText(
        text: TextSpan(
          style:
              const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
          children: buildDiffSpans(
            refText,
            hypText,
            ok: const TextStyle(color: Colors.black87),
            subStyle: const TextStyle(
              color: Colors.orange,
              decoration: TextDecoration.underline,
            ),
            delStyle: const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.underline,
            ),
            insStyle: const TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(
        title: 'AI採点フィードバック',
        backgroundColor:
            isDark ? const Color(0xFF0C1A3E) : const Color(0xFFF3F0FA),
        titleColor: text,
        iconColor: text,
        actions: [
          IconButton(
            tooltip: 'ホームへ',
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isScoring)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('分析中...'),
                      ],
                    ),
                  ),

                // 波形カード（seriesがある時だけ）
                if (widget.sampleSeries.isNotEmpty &&
                    widget.userSeries.isNotEmpty)
                  CollapsibleCard(
                    title: '波形表示（見本: 青 / あなた: 赤）',
                    background: card,
                    child: WaveCompareCard(
                      sampleSeries: widget.sampleSeries,
                      userSeries: widget.userSeries,
                    ),
                  ),
                const SizedBox(height: 12),

                // スコア3点セット（アニメ付き）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AnimatedGauge(
                        label: '波形の正確さ', value: _prosodyScore, isDark: isDark),
                    _AnimatedGauge(
                        label: '単語認識', value: _whisperScore, isDark: isDark),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AnimatedCount(
                          value: _overall,
                          builder: (v) => Text(
                            '${v.round()} 点',
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: text),
                          ),
                        ),
                        Text(
                          _overallLabel,
                          style: TextStyle(
                            fontSize: 18,
                            color: _overall >= 90
                                ? Colors.green
                                : _overall >= 80
                                    ? Colors.lightGreen
                                    : _overall >= 70
                                        ? Colors.orange
                                        : Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('ホームへ'),
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('もう一度分析'),
                      onPressed: _isScoring ? null : _runSttAndScore,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // スクリプト比較
                CollapsibleCard(
                  title: '正解スクリプトとの比較',
                  background: card,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: comparisonChild,
                  ),
                ),

                const SizedBox(height: 12),

                // 自動フィードバック（お好みで外してOK）
                _sectionTitle('抑揚フィードバック', card, Colors.black),
                _feedbackBox(
                  buildProsodyFeedback(_prosodyScore, widget.userSeries),
                  text,
                ),
                const SizedBox(height: 12),
                _sectionTitle('発音フィードバック', card, Colors.black),
                _feedbackBox(
                  buildPronunciationFeedback(
                    _whisperScore,
                    widget.referenceText,
                    _recognizedTextController.text,
                  ),
                  text,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_celebrate) const _CelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color cardColor, Color textColor) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  Widget _feedbackBox(String feedback, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(feedback, style: TextStyle(color: textColor, fontSize: 15)),
    );
  }
}

// =========================
// アニメーション用の小部品
// =========================
class _AnimatedGauge extends StatelessWidget {
  final String label;
  final double value;
  final bool isDark;
  const _AnimatedGauge({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final target = (value.clamp(0, 100)).toDouble();
    final track = isDark ? Colors.white24 : Colors.grey[300]!;
    final percentColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 72,
                  width: 72,
                  child: CircularProgressIndicator(
                    value: v / 100,
                    strokeWidth: 8,
                    backgroundColor: track,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  ),
                ),
                Text('${v.round()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: percentColor)),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: labelColor)),
      ],
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  final double value;
  final Widget Function(double) builder;
  const _AnimatedCount({required this.value, required this.builder});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 100).toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(v),
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Opacity(
            opacity: (1 - (t - 0.2).clamp(0, 1)),
            child: Transform.scale(
              scale: 0.9 + 0.1 * t,
              child: const Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 42)),
                    Text('✨', style: TextStyle(fontSize: 36)),
                    Text('🎊', style: TextStyle(fontSize: 42)),
                    Text('👏', style: TextStyle(fontSize: 36)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
