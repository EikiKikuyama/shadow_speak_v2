class PracticeMaterial {
  final String id;
  final String level;
  final String title;
  final String audioPath;
  final String scriptPath;
  final String tag;
  final int durationSec;
  final int wordCount;

  PracticeMaterial({
    required this.id,
    required this.level,
    required this.title,
    required this.audioPath,
    required this.scriptPath,
    required this.tag,
    required this.durationSec,
    required this.wordCount,
  });

  /// ✅ 空のダミーデータ用
  factory PracticeMaterial.empty() {
    return PracticeMaterial(
      id: '',
      level: '',
      title: '',
      audioPath: '',
      scriptPath: '',
      tag: '',
      durationSec: 0,
      wordCount: 0,
    );
  }

  String get sampleWavPath => audioPath;
}
