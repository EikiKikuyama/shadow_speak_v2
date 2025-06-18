import 'dart:io';
import 'package:flutter/foundation.dart'; // debugPrint 用

class WaveformProcessor {
  static Future<double> calculateProsodyScore(File wavFile) async {
    try {
      final bytes = await wavFile.readAsBytes();

      const int headerSize = 44;
      if (bytes.length <= headerSize) return 0;

      final data = bytes.sublist(headerSize);
      final amplitudes = <double>[];

      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      for (int i = 0; i < byteData.lengthInBytes; i += 2) {
        final sample = byteData.getInt16(i, Endian.little);
        amplitudes.add(sample.toDouble().abs());
      }

      if (amplitudes.isEmpty) return 0;

      int spikes = 0;
      for (int i = 1; i < amplitudes.length; i++) {
        if ((amplitudes[i] - amplitudes[i - 1]).abs() > 1000) {
          spikes++;
        }
      }

      final spikeRatio = spikes / amplitudes.length;
      final score = (spikeRatio * 5000).clamp(0, 100).toDouble();

      return score;
    } catch (e) {
      debugPrint('⚠️ 波形スコア算出エラー: $e');
      return 0;
    }
  }
}
