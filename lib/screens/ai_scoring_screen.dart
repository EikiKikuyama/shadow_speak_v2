import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_model.dart';
import '../widgets/score_widget.dart';
import '../services/waveform_processor.dart';
import '../services/whisper_api_service.dart';
<<<<<<< HEAD
import '../services/ai_scoring_service.dart';
import '../models/word_difference_result.dart';
=======
import '../utils/levenshtein_distance.dart';
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)
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
<<<<<<< HEAD
  String? referenceScript;
  List<WordDifferenceResult>? wordDifferences;
=======
  String? correctScript;
  List<TextSpan>? diffSpans;
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadReferenceScript();
    _analyzeProsody();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transcribeWithWhisper();
    });
=======
    _loadScriptAndAnalyze();
  }

  Future<void> _loadScriptAndAnalyze() async {
    final scriptText = await rootBundle.loadString(widget.material.scriptPath);

    setState(() {
      correctScript = scriptText.trim().toLowerCase();
    });

    _analyzeProsody();
    _transcribeWithWhisper(scriptText);
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)
  }

  Future<void> _loadReferenceScript() async {
    try {
      final scriptContent =
          await File(widget.material.scriptPath).readAsString();
      setState(() {
        referenceScript = scriptContent;
      });
      dev.log('📘 正解スクリプト: $referenceScript');
    } catch (e) {
      debugPrint('❌ スクリプト読み込み失敗: $e');
      referenceScript = '';
    }
  }

  Future<void> _analyzeProsody() async {
    final score = await WaveformProcessor.calculateProsodyScore(
        File(widget.recordedFilePath));
    if (!mounted) return;
    setState(() {
      prosodyScore = score;
    });
  }

<<<<<<< HEAD
  Future<void> _transcribeWithWhisper() async {
    try {
      final whisper = WhisperApiService();
      final result = await whisper.transcribeAudio(widget.recordedFilePath);
=======
  Future<void> _transcribeWithWhisper(String scriptText) async {
    final filePath = widget.recordedFilePath;

    try {
      final whisper = WhisperApiService();
      final result = await whisper.transcribeAudio(filePath);
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)

      if (result == null) {
        debugPrint('❌ Whisperから結果が返りませんでした');
        return;
      }

      final whisperResult = result.trim().toLowerCase();
      final correct = scriptText.trim().toLowerCase();

      dev.log('📝 Whisper結果: $whisperResult');
      dev.log('📘 正解スクリプト: $correct');

      setState(() {
<<<<<<< HEAD
        transcribedText = result;
        whisperScore = AiScoringService.calculateWhisperScore(
          referenceText: referenceScript ?? '',
          transcribedText: result,
        );
        wordDifferences = AiScoringService.evaluateWordDifferences(
          reference: referenceScript ?? '',
          recognized: result,
        );
=======
        transcribedText = whisperResult;
        whisperScore = calculateAccuracy(correct, whisperResult);
        diffSpans = buildDiffTextSpans(correct, whisperResult);
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)
      });
    } catch (e) {
      debugPrint('❌ Whisper実行中のエラー: $e');
    }
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    final isLoading =
        prosodyScore == null || whisperScore == null || referenceScript == null;
=======
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
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)

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
<<<<<<< HEAD
                    const SizedBox(height: 16),
                    Text(
                      'Whisper文字起こし結果：',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(transcribedText ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      '教材スクリプト：',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(referenceScript ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(
                      '単語ごとの一致・不一致',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (wordDifferences != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: wordDifferences!.map((diff) {
                          return Chip(
                            label: Text(
                              '${diff.referenceWord} / ${diff.recognizedWord}',
                            ),
                            backgroundColor: diff.isMatch
                                ? Colors.green[100]
                                : Colors.red[100],
                          );
                        }).toList(),
                      ),
=======
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
>>>>>>> a668456 (🔍 Add DTW implementation for prosody scoring)
                  ],
                ),
              ),
      ),
    );
  }
}
