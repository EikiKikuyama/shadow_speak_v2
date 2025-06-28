import 'package:flutter/material.dart';
import '../models/subtitle_segment.dart';

class SubtitleDisplay extends StatelessWidget {
  final SubtitleSegment? currentSubtitle;
  final List<SubtitleSegment> allSubtitles;

  const SubtitleDisplay({
    Key? key,
    required this.currentSubtitle,
    required this.allSubtitles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: allSubtitles.map((segment) {
        final isActive = segment == currentSubtitle;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            segment.text,
            style: TextStyle(
              fontSize: 18,
              color: isActive ? Colors.blueAccent : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}
