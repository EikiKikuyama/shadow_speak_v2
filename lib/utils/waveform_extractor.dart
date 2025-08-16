import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← assets用に必要
import 'dart:typed_data';

Future<List<double>> extractWaveformFromBytes(Uint8List data) async {
  if (data.length < 44) throw Exception("WAVファイルが小さすぎる");

  final header = ByteData.sublistView(data, 0, 44);
  final sampleRate = header.getUint32(24, Endian.little); // サンプルレート
  final bitsPerSample = header.getUint16(34, Endian.little); // 16bit想定
  final numChannels = header.getUint16(22, Endian.little); // モノラル or ステレオ

  final bytesPerSample = bitsPerSample ~/ 8;
  final totalSamples = (data.length - 44) ~/ bytesPerSample;
  final durationSeconds = totalSamples / sampleRate;

  final rawSamples = <double>[];
  for (int i = 44; i < data.length - 1; i += bytesPerSample * numChannels) {
    final sample = data[i] | (data[i + 1] << 8);
    final signed = Int16List.fromList([sample]).first.toDouble();
    rawSamples.add(signed);
  }

  final targetLength = (durationSeconds * 100).round();
  final result = _resample(rawSamples, targetLength);

  debugPrint("🎯 Final waveform length: ${result.length}");
  return result;
}

Future<List<double>> extractWaveform(File file) async {
  final Uint8List data = await file.readAsBytes();
  return extractWaveformFromBytes(data);
}

Future<List<double>> extractWaveformFromAssets(String assetPath) async {
  final ByteData byteData = await rootBundle.load(assetPath);
  final Uint8List data = byteData.buffer.asUint8List();
  return extractWaveformFromBytes(data);
}

List<double> _resample(List<double> input, int targetLength) {
  final factor = input.length / targetLength;
  return List.generate(targetLength, (i) {
    final start = (i * factor).floor();
    final end = ((i + 1) * factor).floor().clamp(0, input.length);
    final segment = input.sublist(start, end);
    return segment.isNotEmpty
        ? segment.reduce((a, b) => a + b) / segment.length
        : 0;
  });
}

List<double> resampleForDisplay(List<double> data, int targetLength) {
  if (data.length <= targetLength) return data;

  double factor = data.length / targetLength;
  return List.generate(targetLength, (i) => data[(i * factor).floor()]);
}

List<double> processWaveform(List<double> waveform, double totalSeconds) {
  if (waveform.isEmpty) {
    debugPrint("📉 入力waveformが空です");
    return [];
  }

  // マイナス値を0に変換
  List<double> processed =
      waveform.map((value) => max(0, value).toDouble()).toList();
  debugPrint("🔢 processed.length: ${processed.length}");

  // スムージング
  int numSamplesPerSecond = 100;
  int windowSize = max(1, (processed.length / numSamplesPerSecond).floor());

  debugPrint("🪟 windowSize: $windowSize");
  if (windowSize <= 0) return processed;

  List<double> smoothed = [];
  for (int i = 0; i < processed.length - windowSize; i++) {
    double avg = processed.sublist(i, i + windowSize).reduce((a, b) => a + b) /
        windowSize;
    smoothed.add(avg);
  }

  debugPrint("📈 smoothed.length: ${smoothed.length}");
  if (smoothed.isEmpty) return [];

  final maxAmp = smoothed.reduce(max);
  debugPrint("🔊 maxAmp: $maxAmp");
  final safeMaxAmp = maxAmp < 0.001 ? 1.0 : maxAmp;

  final normalized = smoothed.map((e) => (e / safeMaxAmp) * 0.6).toList();
  debugPrint("✅ normalized.length: ${normalized.length}");

  // リサンプリング数を動的に決める（例：1秒100サンプル × totalSeconds）
  final int targetLength = (100 * totalSeconds).round();
  debugPrint('🎯 targetLength for resample: $targetLength');

  final resampled = resampleForDisplay(normalized, targetLength);
  debugPrint('📉 final display waveform length: ${resampled.length}');

  return resampled;
}
