import 'package:flutter/material.dart';

class ScoreWidget extends StatelessWidget {
  final double prosodyScore;
  final double whisperScore;

  const ScoreWidget({
    super.key,
    required this.prosodyScore,
    required this.whisperScore,
  });

  @override
  Widget build(BuildContext context) {
    final double totalScore = ((prosodyScore + whisperScore) / 2).clamp(0, 100);
    final String label = _getScoreLabel(totalScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          totalScore.toStringAsFixed(1),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getLabelColor(totalScore),
          ),
        ),
        const SizedBox(height: 16),
        _buildSubScores(),
      ],
    );
  }

  Widget _buildSubScores() {
    return Column(
      children: [
        Text('抑揚（波形）: ${prosodyScore.toStringAsFixed(1)}'),
        Text('単語認識（Whisper）: ${whisperScore.toStringAsFixed(1)}'),
      ],
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Okay';
    return 'Needs Work';
  }

  Color _getLabelColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
  }
}
