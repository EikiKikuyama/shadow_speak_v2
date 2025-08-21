// 履歴1件分の保存用モデル（壊れても isValid false で弾く）
class ScoreSnapshot {
  final String id; // uuid
  final DateTime at; // 採点日時
  final String referenceText; // 見本
  final String transcribedText; // STT結果
  final double prosody; // 0..100
  final double whisper; // 0..100
  final String? wavPath; // 無い場合あり
  final String schema; // 互換用

  ScoreSnapshot({
    required this.id,
    required this.at,
    required this.referenceText,
    required this.transcribedText,
    required this.prosody,
    required this.whisper,
    required this.schema,
    this.wavPath,
  });

  factory ScoreSnapshot.fromJson(Map<String, dynamic> j) {
    try {
      return ScoreSnapshot(
        id: (j['id'] ?? '') as String,
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
        referenceText: (j['referenceText'] ?? '') as String,
        transcribedText: (j['transcribedText'] ?? '') as String,
        prosody: ((j['prosody'] ?? 0) as num).toDouble(),
        whisper: ((j['whisper'] ?? 0) as num).toDouble(),
        wavPath: j['wavPath'] as String?,
        schema: (j['schema'] ?? 'v1') as String,
      );
    } catch (_) {
      return ScoreSnapshot(
        id: 'invalid',
        at: DateTime.now(),
        referenceText: '',
        transcribedText: '',
        prosody: 0,
        whisper: 0,
        schema: 'invalid',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'referenceText': referenceText,
        'transcribedText': transcribedText,
        'prosody': prosody,
        'whisper': whisper,
        'wavPath': wavPath,
        'schema': schema,
      };

  bool get isValid =>
      id.isNotEmpty && id != 'invalid' && referenceText.isNotEmpty;
}
