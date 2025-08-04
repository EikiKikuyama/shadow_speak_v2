import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/subtitle_segment.dart';

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
