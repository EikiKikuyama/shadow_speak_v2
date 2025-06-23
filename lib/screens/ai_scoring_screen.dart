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

    _analyzeProsody(); // ← DTWスコア
    _transcribeWithWhisper(scriptText); // ← Whisperスコア
  }

  Future<void> _analyzeProsody() async {
    // ★ assets/ を付ける補正
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    ScoreWidget(
                      prosodyScore: prosodyScore!,
                      whisperScore: whisperScore!,
                    ),
                    const SizedBox(height: 32),
                    Text('Whisper結果と正解スクリプト比較：',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
