import 'package:flutter/material.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';

class AiScoringScreen extends StatefulWidget {
  final double whisperScore;
  final double prosodyScore;
  final String referenceText;
  final String transcribedText;
  final String prosodyFeedback;
  final String pronunciationFeedback;

  const AiScoringScreen({
    super.key,
    required this.whisperScore,
    required this.prosodyScore,
    required this.referenceText,
    required this.transcribedText,
    required this.prosodyFeedback,
    required this.pronunciationFeedback,
  });

  @override
  State<AiScoringScreen> createState() => _AiScoringScreenState();
}

class _AiScoringScreenState extends State<AiScoringScreen> {
  @override
  Widget build(BuildContext context) {
    final overallScore =
        ((widget.whisperScore + widget.prosodyScore) / 2).round();

    return Scaffold(
      backgroundColor: const Color(0xFF08254D),
      appBar: const CustomAppBar(
        title: 'AI採点フィードバック',
        backgroundColor: Colors.transparent,
        titleColor: Colors.white,
        iconColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 波形エリア（仮）
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: AspectRatio(
                aspectRatio: 3,
                child: Center(
                  child: Text(
                    '波形表示（見本: 赤・あなた: 青）',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),

            // スコア表示エリア
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreGauge("波形の正確さ", widget.prosodyScore),
                _buildScoreGauge("単語認識", widget.whisperScore),
                Column(
                  children: [
                    Text(
                      '$overallScore 点',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Good Job',
                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                    )
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // スクリプト比較
            _buildSectionTitle('正解スクリプトとの比較'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  children: _buildHighlightedDiff(
                      widget.referenceText, widget.transcribedText),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('抑揚フィードバック'),
            _buildFeedbackBox(widget.prosodyFeedback),

            const SizedBox(height: 16),
            _buildSectionTitle('発音フィードバック'),
            _buildFeedbackBox(widget.pronunciationFeedback),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGauge(String label, double value) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
            ),
            Text('${value.round()}%',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFeedbackBox(String feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        feedback,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// 差分ハイライト処理（ここは簡易）
  List<TextSpan> _buildHighlightedDiff(String reference, String userText) {
    final refWords = reference.split(' ');
    final userWords = userText.split(' ');

    List<TextSpan> spans = [];

    for (int i = 0; i < refWords.length; i++) {
      final ref = refWords[i];
      final usr = (i < userWords.length) ? userWords[i] : "";

      final match = ref.toLowerCase() == usr.toLowerCase();

      spans.add(TextSpan(
        text: '$usr ',
        style: TextStyle(color: match ? Colors.black : Colors.red),
      ));
    }

    return spans;
  }
}
