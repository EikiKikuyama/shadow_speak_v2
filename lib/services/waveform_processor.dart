import 'dart:io';
import 'dart:math';
import '../utils/waveform_extractor.dart';
import '../utils/dtw.dart';

class WaveformProcessor {
  static Future<double> calculateProsodyScore({
    required File recordedFile,
    required String sampleAudioPath,
    bool isAsset = true,
  }) async {
    try {
      print('📥 Prosodyスコア計算スタート');
      print('📄 録音ファイル: ${recordedFile.path}');
      print('🎧 見本ファイル: $sampleAudioPath');

      final sampleWave = isAsset
          ? await extractWaveformFromAssets(sampleAudioPath)
          : extractWaveform(File(sampleAudioPath));
      final recordedWave = extractWaveform(recordedFile);

      print('✅ 見本波形サンプル数: ${sampleWave.length}');
      print('✅ 録音波形サンプル数: ${recordedWave.length}');

      final normalizedSample = _normalize(sampleWave);
      final normalizedRecordedFull = _normalize(recordedWave);

      // 🎯 見本と同じ長さに切り詰める
      final croppedRecorded = normalizedRecordedFull.sublist(
        0,
        min(normalizedSample.length, normalizedRecordedFull.length),
      );

      print(
          '📊 正規化後：sample=${normalizedSample.length}, recorded(cropped)=${croppedRecorded.length}');

      final distance = await calculateDTWDistanceInIsolate(
        normalizedSample,
        croppedRecorded,
      );

      // 🧪 厳しめスコア計算
      const maxScore = 100.0;
      const penaltyFactor = 0.05; // ← ここを強化（前は 0.03）
      final rawScore = maxScore - penaltyFactor * distance;
      final score = rawScore.clamp(0, 100).toDouble();

      print('📈 DTW距離: $distance');
      print('📐 Sample長さ: ${normalizedSample.length}');
      print('📐 CroppedRecorded長さ: ${croppedRecorded.length}');
      print(
          '⚙️ score = 100 - ($penaltyFactor × $distance) = $rawScore → clamped: $score');
      print('🎯 DTWスコア（Prosody）: $score');

      return score;
    } catch (e) {
      print('❌ Prosodyスコア計算エラー: $e');
      return 0.0;
    }
  }

  static List<double> _normalize(List<double> values) {
    if (values.isEmpty) return [];

    // 平均と標準偏差を計算
    final mean = values.reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(
      values.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) /
          values.length,
    );

    if (stdDev == 0) return List.filled(values.length, 0.0); // フラット対策

    // Zスコア正規化
    final zNormalized = values.map((e) => (e - mean) / stdDev).toList();

    // ダウンサンプリング（10個に1つ）
    final downSampled = <double>[];
    for (int i = 0; i < zNormalized.length; i += 10) {
      downSampled.add(zNormalized[i]);
    }

    return downSampled;
  }
}
