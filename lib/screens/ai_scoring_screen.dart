import 'dart:io';
import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../widgets/score_widget.dart';
import '../services/waveform_processor.dart';
import '../services/whisper_api_service.dart'; // WhisperのAPIサービスもimport
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
  double? whisperScore; // ← これを double にする（実際に点数つける想定）
  String? transcribedText;

  @override
  void initState() {
    super.initState();

    _analyzeProsody();

    // dotenvの読み込みが終わった後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transcribeWithWhisper();
    });
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
    final apiKey =
        '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';
    if (apiKey.isEmpty) {
      debugPrint('❌ APIキーが見つかりません。dotenvが読み込まれていない可能性あり');
      return;
    }

    final filePath = widget.recordedFilePath;

    try {
      final whisper = WhisperApiService();
      final result = await whisper.transcribeAudio(filePath); // ✅ 確実に String

      if (result == null) {
        debugPrint('❌ Whisperから結果が返りませんでした');
        return;
      }

      dev.log('📝 Whisper結果: $result');

      setState(() {
        transcribedText = result;
        whisperScore = _evaluateWhisperResult(result);
      });
    } catch (e) {
      debugPrint('❌ Whisper実行中のエラー: $e');
    }
  }

  // 仮の採点関数：今は固定値でOK（あとで精度比較へ）
  double _evaluateWhisperResult(String text) {
    // 将来的には script と照合して一致率で点数出す
    return 75.0;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = prosodyScore == null || whisperScore == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI採点結果'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                ],
              ),
      ),
    );
  }
}
