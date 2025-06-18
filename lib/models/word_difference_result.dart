class WordDifferenceResult {
  final String referenceWord;
  final String recognizedWord;
  final bool isMatch;

  WordDifferenceResult({
    required this.referenceWord,
    required this.recognizedWord,
    required this.isMatch,
  });
}
