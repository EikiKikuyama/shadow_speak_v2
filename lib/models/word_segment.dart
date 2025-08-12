class WordSegment {
  final String word;
  final double start; // 秒単位
  final double end;

  WordSegment({
    required this.word,
    required this.start,
    required this.end,
  });
}
