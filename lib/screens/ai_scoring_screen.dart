import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';

class AiScoringScreen extends ConsumerStatefulWidget {
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
  ConsumerState<AiScoringScreen> createState() => _AiScoringScreenState();
}

class _AiScoringScreenState extends ConsumerState<AiScoringScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;

    final backgroundColor =
        isDarkMode ? const Color(0xFF08254D) : const Color(0xFFF3F0FA);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = Colors.white;
    final sectionTitleColor = isDarkMode ? Colors.black : Colors.black;
    final diffMismatchColor = Colors.red;

    final overallScore =
        ((widget.whisperScore + widget.prosodyScore) / 2).round();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: 'AI採点フィードバック',
        backgroundColor:
            isDarkMode ? const Color(0xFF0C1A3E) : const Color(0xFFF3F0FA),
        titleColor: textColor,
        iconColor: textColor,
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
                color: cardColor,
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
                _buildScoreGauge("波形の正確さ", widget.prosodyScore, textColor),
                _buildScoreGauge("単語認識", widget.whisperScore, textColor),
                Column(
                  children: [
                    Text(
                      '$overallScore 点',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
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

            _buildSectionTitle('正解スクリプトとの比較', cardColor, sectionTitleColor),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: cardColor,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: textColor),
                  children: _buildHighlightedDiff(widget.referenceText,
                      widget.transcribedText, textColor, diffMismatchColor),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('抑揚フィードバック', cardColor, sectionTitleColor),
            _buildFeedbackBox(widget.prosodyFeedback, textColor),

            const SizedBox(height: 16),
            _buildSectionTitle('発音フィードバック', cardColor, sectionTitleColor),
            _buildFeedbackBox(widget.pronunciationFeedback, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGauge(String label, double value, Color textColor) {
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
            ),
            Text('${value.round()}%', style: TextStyle(color: textColor)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: textColor)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color cardColor, Color textColor) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 4),
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

  Widget _buildFeedbackBox(String feedback, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        feedback,
        style: TextStyle(color: textColor),
      ),
    );
  }

  List<TextSpan> _buildHighlightedDiff(String reference, String userText,
      Color matchColor, Color mismatchColor) {
    final refWords = reference.split(' ');
    final userWords = userText.split(' ');

    List<TextSpan> spans = [];

    for (int i = 0; i < refWords.length; i++) {
      final ref = refWords[i];
      final usr = (i < userWords.length) ? userWords[i] : "";

      final match = ref.toLowerCase() == usr.toLowerCase();

      spans.add(TextSpan(
        text: '$usr ',
        style: TextStyle(color: match ? matchColor : mismatchColor),
      ));
    }

    return spans;
  }
}
