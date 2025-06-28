import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/subtitle_segment.dart';

Future<List<SubtitleSegment>> loadSubtitles(String filename) async {
  final String jsonStr =
      await rootBundle.loadString('assets/subtitles/$filename.json');
  final List<dynamic> jsonData = json.decode(jsonStr);
  return jsonData.map((e) => SubtitleSegment.fromJson(e)).toList();
}
