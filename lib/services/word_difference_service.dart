import '../models/word_difference_result.dart';

class WordDifferenceService {
  static List<WordDifferenceResult> compareWords({
    required String referenceText,
    required String recognizedText,
  }) {
    final refWords = referenceText.toLowerCase().trim().split(RegExp(r'\s+'));
    final recWords = recognizedText.toLowerCase().trim().split(RegExp(r'\s+'));

    final maxLength =
        refWords.length > recWords.length ? refWords.length : recWords.length;
    final results = <WordDifferenceResult>[];

    for (int i = 0; i < maxLength; i++) {
      final ref = (i < refWords.length) ? refWords[i] : '';
      final rec = (i < recWords.length) ? recWords[i] : '';
      final match = ref == rec;

      results.add(WordDifferenceResult(
        referenceWord: ref,
        recognizedWord: rec,
        isMatch: match,
      ));
    }

    return results;
  }
}
