import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_model.dart';
import '../widgets/score_widget.dart';
import '../services/waveform_processor.dart';
import '../services/whisper_api_service.dart';
import '../utils/levenshtein_distance.dart';
import 'dart:developer' as dev;

class AiScoringScreen extends StatefulWidget {
  final PracticeMaterial material;
  final String recordedFilePath;

  const AiScoringScreen({
    super.key,
    required this.material,
    required this.recordedFilePath,
  });

  @override
  State<AiScoringScreen> createState() => _AiScoringScreenState();
}

class _AiScoringScreenState extends State<AiScoringScreen> {
  double? prosodyScore;
  double? whisperScore;
  String? transcribedText;
  String? correctScript;
  List<TextSpan>? diffSpans;
  String? prosodyFeedback;
  String? grammarFeedback;

  @override
  void initState() {
    super.initState();
    _loadScriptAndAnalyze();
  }

  Future<void> _loadScriptAndAnalyze() async {
    final scriptText = await rootBundle.loadString(widget.material.scriptPath);

    setState(() {
      correctScript = scriptText.trim().toLowerCase();
    });

    _analyzeProsody();
    _transcribeWithWhisper(scriptText);
  }

  Future<void> _analyzeProsody() async {
    final fixedAudioPath = widget.material.audioPath.startsWith('assets/')
        ? widget.material.audioPath
        : 'assets/${widget.material.audioPath}';

    final score = await WaveformProcessor.calculateProsodyScore(
      recordedFile: File(widget.recordedFilePath),
      sampleAudioPath: fixedAudioPath,
      isAsset: true,
    );

    if (!mounted) return;
    setState(() {
      prosodyScore = score;
      prosodyFeedback = generateProsodyFeedback(score);
    });
  }

  Future<void> _transcribeWithWhisper(String scriptText) async {
    final filePath = widget.recordedFilePath;

    try {
      final whisper = WhisperApiService();
      final result = await whisper.transcribeAudio(filePath);

      if (result == null) {
        debugPrint('❌ Whisperから結果が返りませんでした');
        return;
      }

      final whisperResult = result.trim().toLowerCase();
      final correct = scriptText.trim().toLowerCase();

      dev.log('📝 Whisper結果: $whisperResult');
      dev.log('📘 正解スクリプト: $correct');

      setState(() {
        transcribedText = whisperResult;
        whisperScore = calculateAccuracy(correct, whisperResult);
        grammarFeedback = generateGrammarFeedback(whisperScore!);
        diffSpans = buildDiffTextSpans(correct, whisperResult);
      });
    } catch (e) {
      debugPrint('❌ Whisper実行中のエラー: $e');
    }
  }

  List<TextSpan> buildDiffTextSpans(String correct, String actual) {
    final List<TextSpan> spans = [];
    final diff = levenshteinDiff(correct, actual);

    for (var d in diff) {
      spans.add(TextSpan(
        text: d.char,
        style: TextStyle(
          color: d.type == DiffType.equal
              ? Colors.black
              : d.type == DiffType.insert
                  ? Colors.green
                  : Colors.red,
          backgroundColor: d.type == DiffType.equal
              ? null
              : d.type == DiffType.insert
                  ? Colors.green.shade100
                  : Colors.red.shade100,
        ),
      ));
    }

    return spans;
  }

  String generateProsodyFeedback(double score) {
    if (score >= 95) {
      return "完璧です！ネイティブレベルの自然な抑揚が表現できています。";
    } else if (score >= 85) {
      return "非常に良いです！ごくわずかにリズムのズレがありますが、全体として自然です。";
    } else if (score >= 75) {
      return "良好です！一部の音節で抑揚が弱くなっています。";
    } else if (score >= 65) {
      return "安定していますが、抑揚が平坦に感じられる箇所があります。";
    } else if (score >= 55) {
      return "リズムは比較的整っていますが、全体的に抑揚が単調です。";
    } else if (score >= 45) {
      return "抑揚の欠如が目立ちます。音の高低を意識して練習してみましょう。";
    } else if (score >= 30) {
      return "リズム・抑揚ともにズレが多く、改善が必要です。短いフレーズ練習が有効です。";
    } else {
      return "全体的に平坦で、自然さが感じられません。声に強弱をつける練習から始めましょう。";
    }
  }

  String generateGrammarFeedback(double score) {
    if (score >= 95) {
      return "ほぼ完全です。文法の誤りはほとんどありません。";
    } else if (score >= 85) {
      return "非常に正確です。細かな文法の不自然さがわずかにあります。";
    } else if (score >= 75) {
      return "おおむね正確ですが、少し文法ミスがあります。";
    } else if (score >= 65) {
      return "いくつかの文法ミスにより、意味が部分的に不明瞭です。";
    } else if (score >= 50) {
      return "文法エラーが目立ち、意味が伝わりづらい箇所があります。";
    } else if (score >= 35) {
      return "多くの文法的な誤りで、伝えたい内容が不明瞭になっています。";
    } else {
      return "文法が崩壊しており、ほとんど意味が伝わっていません。基礎文法の復習をおすすめします。";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        prosodyScore == null || whisperScore == null || diffSpans == null;

    return Scaffold(
      appBar: AppBar(title: const Text('AI採点結果')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    ScoreWidget(
                      prosodyScore: prosodyScore!,
                      whisperScore: whisperScore!,
                    ),
                    const SizedBox(height: 24),
                    Text("🗣️ 発音フィードバック：$prosodyFeedback",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text("📘 文法フィードバック：$grammarFeedback",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 32),
                    const Text('Whisper結果と正解スクリプト比較：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: diffSpans!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
