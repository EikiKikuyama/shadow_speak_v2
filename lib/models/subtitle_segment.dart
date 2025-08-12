import 'word_segment.dart';

class SubtitleSegment {
  final double start;
  final double end;
  final String text;
  final String translation;
  final List<WordSegment> words; // ✅ 明示的に必須にする

  SubtitleSegment({
    required this.start,
    required this.end,
    required this.text,
    required this.words, // ✅ ← required に変更
    this.translation = '',
  });

  factory SubtitleSegment.fromJson(Map<String, dynamic> json) {
    final wordList = (json['words'] as List<dynamic>?)
            ?.map((w) => WordSegment(
                  word: w['word'].toString(),
                  start: (w['start'] ?? 0.0).toDouble(),
                  end: (w['end'] ?? 0.0).toDouble(),
                ))
            .toList() ??
        []; // ← ✅ nullのときは空リストにする！

    return SubtitleSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
      translation: json['translation'] ?? '',
      words: wordList,
    );
  }
}
