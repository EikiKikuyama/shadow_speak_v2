import 'package:flutter/material.dart';
import '../models/word_segment.dart';

class FocusedKaraokeSubtitle extends StatefulWidget {
  final List<WordSegment> wordSegments;
  final Duration currentTime;
  final Color highlightColor;
  final Color defaultColor;

  const FocusedKaraokeSubtitle({
    super.key,
    required this.wordSegments,
    required this.currentTime,
    this.highlightColor = Colors.orange,
    this.defaultColor = Colors.white,
  });

  @override
  State<FocusedKaraokeSubtitle> createState() => _FocusedKaraokeSubtitleState();
}

class _FocusedKaraokeSubtitleState extends State<FocusedKaraokeSubtitle> {
  WordSegment? _lastActiveWord;

  WordSegment? _getActiveWord(Duration currentTime) {
    final currentMs = currentTime.inMilliseconds;

    try {
      final active = widget.wordSegments.firstWhere(
        (w) =>
            (w.start * 1000).round() <= currentMs &&
            currentMs <= (w.end * 1000).round(),
      );
      _lastActiveWord = active;
      return active;
    } catch (_) {
      // 無音区間：前回の単語を維持して表示
      return _lastActiveWord;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeWord = _getActiveWord(widget.currentTime);

    if (activeWord == null) {
      return const SizedBox(); // 最初の表示前（まだ発話が始まってない）
    }

    final index = widget.wordSegments.indexOf(activeWord);
    final start = (index - 3).clamp(0, widget.wordSegments.length - 1);
    final end = (index + 4).clamp(0, widget.wordSegments.length);
    final displayWords = widget.wordSegments.sublist(start, end);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: displayWords.map((segment) {
        final isActive = segment == activeWord;
        return Text(
          segment.word,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? widget.highlightColor : widget.defaultColor,
          ),
        );
      }).toList(),
    );
  }
}
