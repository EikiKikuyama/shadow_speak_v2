import '../services/word_difference_service.dart';
import '../models/word_difference_result.dart';

class AiScoringService {
  /// Whisperの結果と正解スクリプトを比較してスコア（0〜100）を返す
  static double calculateWhisperScore({
    required String referenceText,
    required String transcribedText,
  }) {
    final ref = referenceText.toLowerCase().trim();
    final res = transcribedText.toLowerCase().trim();

    final distance = _levenshtein(ref, res);
    final maxLen = ref.isNotEmpty ? ref.length : 1;

    double similarity = (1 - distance / maxLen).clamp(0.0, 1.0);
    return (similarity * 100).roundToDouble();
  }

  /// レーベンシュタイン距離の計算
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix = List.generate(
      s.length + 1,
      (_) => List<int>.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }

  /// 単語ごとの一致判定リストを返す
  static List<WordDifferenceResult> evaluateWordDifferences({
    required String reference,
    required String recognized,
  }) {
    return WordDifferenceService.compareWords(
      referenceText: reference,
      recognizedText: recognized,
    );
  }

  static List<String> generateFeedbackComments(
      List<WordDifferenceResult> results) {
    List<String> comments = [];

    for (final result in results) {
      if (!result.isMatch) {
        comments.add(
            "単語 '${result.recognizedWord}' は '${result.referenceWord}' と異なります。");
      }
    }

    return comments;
  }

  /// 一致率スコアを計算（オプション）
  static double calculateWordMatchScore(List<WordDifferenceResult> results) {
    if (results.isEmpty) return 0.0;
    final matchedCount = results.where((r) => r.isMatch).length;
    return (matchedCount / results.length * 100).roundToDouble();
  }
}
