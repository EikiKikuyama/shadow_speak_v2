import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shadow_speak_v2/models/stt_result.dart';

class WhisperApiService {
  Future<SttResult?> transcribeAudio(String filePath) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ APIキーが見つかりません（dotenv未設定）');
      return null;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        // 必要に応じてmime調整（m4a/ogg等なら変更）
        contentType: MediaType('audio', 'wav'),
      ))
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'en'
      // ↓ これが肝：タイムスタンプを取る
      ..fields['response_format'] = 'verbose_json'
      ..fields['timestamp_granularities[]'] = 'word';

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      print('❌ Whisper API error: ${response.statusCode}');
      print('⚠️ Response body: ${response.body}');
      return null;
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);
    final fullText = (jsonData['text'] ?? '').toString();

    // 返却形式は model/設定で「words直下」または「segments[].words」になることがある
    final List<SttWord> words = [];

    // パターン1: words がトップレベルにある
    if (jsonData['words'] is List) {
      for (final w in (jsonData['words'] as List)) {
        final word = (w['word'] ?? '').toString();
        final start = (w['start'] ?? 0).toDouble();
        final end = (w['end'] ?? 0).toDouble();
        if (word.isNotEmpty) words.add(SttWord(word, start, end));
      }
    }

    // パターン2: segments[].words の中にある
    if (words.isEmpty && jsonData['segments'] is List) {
      for (final seg in (jsonData['segments'] as List)) {
        if (seg['words'] is List) {
          for (final w in (seg['words'] as List)) {
            final word = (w['word'] ?? '').toString();
            final start = (w['start'] ?? 0).toDouble();
            final end = (w['end'] ?? 0).toDouble();
            if (word.isNotEmpty) words.add(SttWord(word, start, end));
          }
        }
      }
    }

    return SttResult(fullText: fullText, words: words);
  }
}
