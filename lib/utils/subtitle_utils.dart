import '../models/subtitle_segment.dart';

SubtitleSegment? getCurrentSubtitle(
    List<SubtitleSegment> segments, Duration position) {
  final seconds = position.inMilliseconds / 1000;
  for (final s in segments) {
    if (seconds >= s.start && seconds <= s.end) {
      return s;
    }
  }
  return null;
}
