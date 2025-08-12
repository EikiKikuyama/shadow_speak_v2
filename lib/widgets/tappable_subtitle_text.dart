import 'package:flutter/material.dart';

class TappableSubtitleText extends StatelessWidget {
  final List<String> words;
  final void Function(String) onTap;
  final String? highlightedWord;
  final bool isDarkMode;

  const TappableSubtitleText({
    super.key,
    required this.words,
    required this.onTap,
    this.highlightedWord,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: words.map((word) {
        final isHighlighted = word == highlightedWord;
        return GestureDetector(
          onTap: () => onTap(word),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.yellow
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              word,
              style: TextStyle(
                fontSize: 20,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
