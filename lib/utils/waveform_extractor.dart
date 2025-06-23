import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← assets用に必要

/// 録音ファイル（File）から波形データを抽出
List<double> extractWaveform(File file) {
  final List<double> amplitudes = [];
  final Uint8List data = file.readAsBytesSync();

  // WAVのヘッダーをスキップ
  int startOffset = 44;
  int step = 50;

  for (int i = startOffset; i < data.length - 1; i += step) {
    int sample = (data[i] | (data[i + 1] << 8)).toSigned(16);
    amplitudes.add(sample.toDouble());
  }
  debugPrint("📊 抽出したサンプル数: ${amplitudes.length}");
  debugPrint("📄 extractWaveform(): path = ${file.path}");
  debugPrint("📄 ファイル存在する？ ${file.existsSync()}");
  return amplitudes;
}

/// assets内の音声ファイルから波形データを抽出（非同期）
Future<List<double>> extractWaveformFromAssets(String assetPath) async {
  final ByteData byteData = await rootBundle.load(assetPath);
  final Uint8List data = byteData.buffer.asUint8List();
  final List<double> amplitudes = [];
  int step = 50;

  for (int i = 0; i < data.length - 1; i += step) {
    int sample = (data[i] | (data[i + 1] << 8)).toSigned(16);
    amplitudes.add(sample.toDouble());
  }

  return amplitudes;
}

List<double> processWaveform(List<double> waveform) {
  if (waveform.isEmpty) {
    debugPrint("📉 入力waveformが空です");
    return [];
  }

  // マイナス値を0に変換
  List<double> processed =
      waveform.map((value) => max(0, value).toDouble()).toList();
  debugPrint("🔢 processed.length: ${processed.length}");

  // スムージング
  int numSamplesPerSecond = 60;
  int windowSize = (processed.length / numSamplesPerSecond).floor();
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

  return normalized;
}
