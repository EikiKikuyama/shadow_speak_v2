import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

Future<List<dynamic>> _loadJsonArray(String path) async {
  final raw = await rootBundle.loadString(path);
  final data = json.decode(raw);

  // 1) そのまま配列
  if (data is List) return data;

  // 2) オブジェクトの中に配列があるパターンに対応
  if (data is Map<String, dynamic>) {
    // ありがちなキーを順に探す
    for (final key in const ['segments', 'data', 'items', 'lines']) {
      final v = data[key];
      if (v is List) return v;
    }
    // 3) {"text": "..."} しか無い等 → 行に分割してダミー時刻で返す（最終手段）
    // ※ 本当に時刻が無いファイルだった場合のフォールバック（全文表示だけは可）
    if (data['text'] is String) {
      final text = (data['text'] as String).trim();
      final parts = text.split(RegExp(r'\s*\n+\s*')); // 改行で分割
      return parts
          .where((e) => e.isNotEmpty)
          .map((e) => {
                'start': 0.0,
                'end': 0.0,
                'text': e,
                'translation': '',
                'words': <dynamic>[],
              })
          .toList();
    }
  }

  throw FormatException('JSON array (or known nested array) expected: $path');
}

/// EN/JA どちらの形にも対応して SubtitleSegment[] を作る
Future<List<SubtitleSegment>> loadSubtitles(String basePath) async {
  // EN: assets/subtitles/<base>.json
  final enList = await _loadJsonArray('assets/subtitles/$basePath.json');

  // JA: assets/subtitles/<base>.ja.json（無ければ空配列扱い）
  List<dynamic>? jaList;
  try {
    jaList = await _loadJsonArray('assets/subtitles/$basePath.ja.json');
  } catch (_) {
    jaList = null;
  }

  final out = <SubtitleSegment>[];
  for (var i = 0; i < enList.length; i++) {
    final e = enList[i];
    // ① オブジェクト形式 {start,end,text,words?,translation?}
    if (e is Map<String, dynamic>) {
      final words = ((e['words'] as List?) ?? [])
          .map((w) => WordSegment(
                word: w['word'].toString(),
                start: (w['start'] ?? 0).toDouble(),
                end: (w['end'] ?? 0).toDouble(),
              ))
          .toList();

      String ja = '';
      if (e['translation'] is String) {
        ja = e['translation'];
      } else if (jaList != null && i < jaList.length && jaList[i] is String) {
        ja = jaList[i] as String;
      }

      out.add(SubtitleSegment(
        start: (e['start'] as num?)?.toDouble() ?? 0.0,
        end: (e['end'] as num?)?.toDouble() ?? 0.0,
        text: (e['text'] ?? '').toString(),
        words: words,
        translation: ja,
      ));
    }
    // ② 文字列だけの配列 ["...", "..."]
    else if (e is String) {
      final ja = (jaList != null && i < jaList.length && jaList[i] is String)
          ? (jaList[i] as String)
          : '';
      out.add(SubtitleSegment(
        start: 0.0,
        end: 0.0,
        text: e,
        words: const [],
        translation: ja,
      ));
    }
    // ③ 想定外はスキップ
  }
  return out;
}

/// 単語配列のローダ（堅牢版）
Future<List<WordSegment>> loadWordSegments(String basePath) async {
  // 1) まず <base>_words.json を試す
  try {
    final raw =
        await rootBundle.loadString('assets/subtitles/${basePath}_words.json');
    final data = json.decode(raw);

    // 素直な配列
    if (data is List) {
      return data.map<WordSegment>((w) {
        return WordSegment(
          word: w['word'].toString(),
          start: (w['start'] ?? 0).toDouble(),
          end: (w['end'] ?? 0).toDouble(),
        );
      }).toList();
    }
    // { "words": [...] } のような形
    if (data is Map<String, dynamic> && data['words'] is List) {
      final list = data['words'] as List;
      return list.map<WordSegment>((w) {
        return WordSegment(
          word: w['word'].toString(),
          start: (w['start'] ?? 0).toDouble(),
          end: (w['end'] ?? 0).toDouble(),
        );
      }).toList();
    }
  } catch (_) {
    // 例外は無視してフォールバックへ
  }

  // 2) フォールバック：<base>.json のセグメント内 words をフラット化
  try {
    final segments = await loadSubtitles(basePath); // 既存関数を再利用
    final flattened = <WordSegment>[];

    for (final s in segments) {
      if (s.words.isNotEmpty) {
        flattened.addAll(s.words);
        continue;
      }

      // 3) さらにフォールバック：text を単語に分割して均等割り
      final txt = s.text.trim();
      if (txt.isEmpty) continue;

      final tokens =
          txt.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (tokens.isEmpty) continue;

      final segDur = (s.end - s.start);
      // 秒で来る前提なので、最低 0.2s は確保
      final safeDur = segDur.isFinite && segDur > 0 ? segDur : 0.2;
      final step = safeDur / tokens.length;
      var t = s.start;

      for (final w in tokens) {
        final start = t;
        final end = t + step;
        flattened.add(WordSegment(word: w, start: start, end: end));
        t = end;
      }
    }

    return flattened;
  } catch (_) {
    // どうしても無理なら空
    return [];
  }
}
