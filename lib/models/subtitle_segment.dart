class SubtitleSegment {
  final double start;
  final double end;
  final String text;

  SubtitleSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  factory SubtitleSegment.fromJson(Map<String, dynamic> json) {
    return SubtitleSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
    );
  }
}
