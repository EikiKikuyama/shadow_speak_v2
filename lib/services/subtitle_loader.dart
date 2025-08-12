import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

Future<List<SubtitleSegment>> loadSubtitles(String filename) async {
  if (filename.isEmpty) {
    throw Exception("❌ subtitle filename is empty!");
  }

  final String jsonStr =
      await rootBundle.loadString('assets/subtitles/$filename.json');

  // 🔽 jsonMapとしてパースし、"segments" を抽出
  final Map<String, dynamic> jsonMap = json.decode(jsonStr);
  final List<dynamic> segments = jsonMap['segments'];

  return segments.map((e) => SubtitleSegment.fromJson(e)).toList();
}

Future<List<WordSegment>> loadWordSegments(String filename) async {
  final jsonString =
      await rootBundle.loadString('assets/subtitles/$filename.json');
  final jsonData = json.decode(jsonString);

  final segments = jsonData['segments'] as List<dynamic>;
  final List<WordSegment> wordSegments = [];

  for (final segment in segments) {
    final words = segment['words'] as List<dynamic>?;
    if (words == null) continue;

    for (final word in words) {
      wordSegments.add(WordSegment(
        word: word['word'].toString().trim(),
        start: (word['start'] ?? 0.0).toDouble(),
        end: (word['end'] ?? 0.0).toDouble(),
      ));
    }
  }

  return wordSegments;
}
