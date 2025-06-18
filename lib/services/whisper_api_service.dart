import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ← dotenvをimport
import 'dart:convert';

class WhisperApiService {
  Future<String?> transcribeAudio(String filePath) async {
    // ✅ .envからAPIキーを取得
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ APIキーが見つかりません（dotenv未設定の可能性）');
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
        contentType: MediaType('audio', 'wav'),
      ))
      ..fields['model'] = 'whisper-1';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['text'];
    } else {
      print('❌ Whisper API error: ${response.statusCode}');
      print('⚠️ Response body: ${response.body}');
      return null;
    }
  }
}
