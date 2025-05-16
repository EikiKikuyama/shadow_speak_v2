// lib/utils/waveform_extractor.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

List<double> extractWaveform(File file) {
  final List<double> amplitudes = [];
  final Uint8List data = file.readAsBytesSync();
  int step = 50;

  for (int i = 0; i < data.length - 1; i += step) {
    int sample = (data[i] | (data[i + 1] << 8)).toSigned(16);
    amplitudes.add(sample.toDouble());
  }

  return amplitudes;
}

List<double> processWaveform(List<double> waveform) {
  if (waveform.isEmpty) return [];

  List<double> processed =
      waveform.map((value) => max(0, value).toDouble()).toList();
  int numSamplesPerSecond = 30;
  int windowSize = (processed.length / numSamplesPerSecond).floor();
  if (windowSize <= 0) return processed;

  List<double> smoothedWaveform = [];
  for (int i = 0; i < processed.length - windowSize; i++) {
    double avg = processed.sublist(i, i + windowSize).reduce((a, b) => a + b) /
        windowSize;
    smoothedWaveform.add(avg);
  }

  return smoothedWaveform.map((e) => e / 10).toList();
}
