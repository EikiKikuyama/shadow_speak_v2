// lib/audio/waveform_pipeline.dart
import 'dart:math';

class WaveformPipelineConfig {
  final double alpha; // EMA α (既定 0.18)
  final int rmsWinMs; // RMS窓 (既定 10ms)
  final int hopMs; // ホップ (既定 5ms -> 200fps)
  final int lagMs; // 固定レイテンシ補正 (+で右へシフト)

  const WaveformPipelineConfig({
    this.alpha = 0.18,
    this.rmsWinMs = 10,
    this.hopMs = 5,
    this.lagMs = 0,
  });
}

class WaveformPipeline {
  /// raw: PCM(-1..1)モノラル
  static List<double> process({
    required List<double> raw,
    required int sampleRate,
    required WaveformPipelineConfig cfg,
  }) {
    if (raw.isEmpty) return const [];

    // 0) LAG補正（録音を右へシフト）
    final lagSamples = ((cfg.lagMs / 1000.0) * sampleRate).round();
    final lagged = _applyLagRightShift(raw, lagSamples);

    // 1) 整流（絶対値）
    final rectified = lagged.map((v) => v.abs()).toList();

    // 2) RMS(10ms)
    final win = max(1, (sampleRate * (cfg.rmsWinMs / 1000.0)).round());
    final hop =
        max(1, (sampleRate * (cfg.hopMs / 1000.0)).round()); // 5ms -> 200fps
    final rms = _frameRMS(rectified, win, hop);

    // 3) EMA
    final ema = _ema(rms, cfg.alpha);

    // 4) P95正規化（0..1）
    final p95 = _percentile(ema, 95);
    final norm = (p95 <= 1e-9)
        ? List<double>.filled(ema.length, 0.0)
        : ema.map((x) => (x / p95).clamp(0.0, 1.0)).toList();

    return norm;
  }

  static List<double> _applyLagRightShift(List<double> x, int shift) {
    if (shift <= 0) return x;
    final out = List<double>.filled(x.length + shift, 0.0);
    for (int i = 0; i < x.length; i++) {
      out[i + shift] = x[i];
    }
    return out;
  }

  static List<double> _frameRMS(List<double> x, int win, int hop) {
    final res = <double>[];
    if (x.length < win) return res;
    for (int start = 0; start + win <= x.length; start += hop) {
      double sumSq = 0.0;
      for (int i = 0; i < win; i++) {
        final v = x[start + i];
        sumSq += v * v;
      }
      res.add(sqrt(sumSq / win));
    }
    return res;
  }

  static List<double> _ema(List<double> x, double alpha) {
    if (x.isEmpty) return const [];
    final y = List<double>.filled(x.length, 0.0);
    y[0] = x[0];
    for (int i = 1; i < x.length; i++) {
      y[i] = alpha * x[i] + (1 - alpha) * y[i - 1];
    }
    return y;
  }

  static double _percentile(List<double> x, int p) {
    if (x.isEmpty) return 0.0;
    final sorted = List<double>.from(x)..sort();
    final idx =
        ((p / 100.0) * (sorted.length - 1)).clamp(0, sorted.length - 1).round();
    return sorted[idx];
  }
}
