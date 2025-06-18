import 'dart:io';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../widgets/score_widget.dart';
import '../services/waveform_processor.dart';
import '../services/whisper_api_service.dart';
import '../services/ai_scoring_service.dart';
import '../models/word_difference_result.dart';
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
  String? referenceScript;
  List<WordDifferenceResult>? wordDifferences;

  @override
  void initState() {
    super.initState();
    _loadReferenceScript();
    _analyzeProsody();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transcribeWithWhisper();
    });
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

  Future<void> _transcribeWithWhisper() async {
    try {
      final whisper = WhisperApiService();
      final result = await whisper.transcribeAudio(widget.recordedFilePath);

      if (result == null) {
        debugPrint('❌ Whisperから結果が返りませんでした');
        return;
      }

      dev.log('📝 Whisper結果: $result');

      setState(() {
        transcribedText = result;
        whisperScore = AiScoringService.calculateWhisperScore(
          referenceText: referenceScript ?? '',
          transcribedText: result,
        );
        wordDifferences = AiScoringService.evaluateWordDifferences(
          reference: referenceScript ?? '',
          recognized: result,
        );
      });
    } catch (e) {
      debugPrint('❌ Whisper実行中のエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        prosodyScore == null || whisperScore == null || referenceScript == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI採点結果'),
      ),
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
                  ],
                ),
              ),
      ),
    );
  }
}
