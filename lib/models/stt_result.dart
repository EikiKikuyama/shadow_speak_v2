// lib/models/stt_result.dart
class SttWord {
  final String text;
  final double startSec;
  final double endSec;
  SttWord(this.text, this.startSec, this.endSec);
}

class SttResult {
  final String fullText;
  final List<SttWord> words;
  const SttResult({required this.fullText, required this.words});
}
