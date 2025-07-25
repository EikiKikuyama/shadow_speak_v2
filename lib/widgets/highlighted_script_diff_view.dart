import 'package:flutter/material.dart';
import '../../models/word_difference_result.dart';

class HighlightedScriptDiffView extends StatelessWidget {
  final List<WordDifferenceResult> wordDiffs;

  const HighlightedScriptDiffView({super.key, required this.wordDiffs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: wordDiffs.map((word) {
        final isMatch = word.isMatch;
        return Text(
          word.recognizedWord,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isMatch ? Colors.black : Colors.red,
            backgroundColor:
                isMatch ? Colors.transparent : Colors.yellow.withOpacity(0.4),
          ),
        );
      }).toList(),
    );
  }
}
