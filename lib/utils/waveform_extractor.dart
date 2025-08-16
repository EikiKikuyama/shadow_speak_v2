// utils/waveform_extractor.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// 生PCMとサンプルレートのペア（samplesは -1.0..1.0 のモノラル）
class WavePCM {
  final List<double> samples;
  final int sampleRate;
  WavePCM(this.samples, this.sampleRate);
}

/// ─────────────────────────────────────────────────────────
/// WAV デコード（16/24/32bit PCM, LE）→ モノラル(-1..1)
/// ─────────────────────────────────────────────────────────
Future<WavePCM> _decodeWavFromBytes(Uint8List data) async {
  if (data.length < 44) {
    throw Exception("WAVヘッダが不正（サイズ不足）");
  }
  final hdr = ByteData.sublistView(data, 0, 44);
  final sampleRate = hdr.getUint32(24, Endian.little);
  final numChannels = hdr.getUint16(22, Endian.little);
  final bitsPerSample = hdr.getUint16(34, Endian.little);
  final bytesPerSam = bitsPerSample ~/ 8;

  if (!(bitsPerSample == 16 || bitsPerSample == 24 || bitsPerSample == 32)) {
    throw Exception("16/24/32bit PCMのみ対応: $bitsPerSample");
  }

  final body = data.sublist(44);
  final out = <double>[];

  // リトルエンディアン → 符号付き整数 → [-1,1] 正規化
  for (int i = 0;
      i + bytesPerSam * numChannels <= body.length;
      i += bytesPerSam * numChannels) {
    double sum = 0;
    for (int ch = 0; ch < numChannels; ch++) {
      final ofs = i + ch * bytesPerSam;
      if (bitsPerSample == 16) {
        final lo = body[ofs];
        final hi = body[ofs + 1];
        final v = Int16List.fromList([(hi << 8) | lo]).first;
        sum += v / 32768.0;
      } else if (bitsPerSample == 24) {
        final b0 = body[ofs];
        final b1 = body[ofs + 1];
        final b2 = body[ofs + 2];
        int raw = (b2 << 16) | (b1 << 8) | b0;
        if ((raw & 0x800000) != 0) raw |= ~0xFFFFFF; // 符号拡張
        sum += raw / 8388608.0;
      } else {
        // 32bit signed int を想定（float PCMは別実装にする）
        final b0 = body[ofs];
        final b1 = body[ofs + 1];
        final b2 = body[ofs + 2];
        final b3 = body[ofs + 3];
        int raw = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
        sum += raw / 2147483648.0;
      }
    }
    out.add(sum / numChannels); // ステレオ→平均でモノラル化
  }
  return WavePCM(out, sampleRate);
}

Future<WavePCM> decodeWaveFromFile(File file) async {
  final bytes = await file.readAsBytes();
  return _decodeWavFromBytes(bytes);
}

Future<WavePCM> decodeWaveFromAssets(String assetPath) async {
  final bd = await rootBundle.load(assetPath);
  return _decodeWavFromBytes(bd.buffer.asUint8List());
}

/// ─────────────────────────────────────────────────────────
/// 波形パイプライン：RMS(10ms/5ms) → 圧縮 → EMA → 0..1
/// 出力は等間隔 5ms 刻み（= 200サンプル/秒）
/// ─────────────────────────────────────────────────────────
List<double> _rms(List<double> x,
    {required int sampleRate, int windowMs = 10, int hopMs = 5}) {
  final w = (sampleRate * windowMs / 1000).round().clamp(1, 1 << 30);
  final h = (sampleRate * hopMs / 1000).round().clamp(1, 1 << 30);
  final out = <double>[];
  for (int i = 0; i + w <= x.length; i += h) {
    double sum = 0;
    for (int j = 0; j < w; j++) {
      final v = x[i + j];
      sum += v * v;
    }
    out.add(math.sqrt(sum / w));
  }
  return out;
}

List<double> _compress(List<double> x, {double gamma = 0.6}) =>
    x.map((v) => math.pow(v, gamma).toDouble()).toList();

List<double> _ema(List<double> x, {double alpha = 0.25}) {
  if (x.isEmpty) return x;
  final y = List<double>.filled(x.length, 0);
  y[0] = x[0];
  for (int i = 1; i < x.length; i++) {
    y[i] = alpha * x[i] + (1 - alpha) * y[i - 1];
  }
  return y;
}

List<double> _normalize01(List<double> x, {double eps = 1e-9}) {
  double mx = 0;
  for (final v in x) {
    if (v > mx) mx = v;
  }
  if (mx < eps) return List.filled(x.length, 0);
  return x.map((v) => v / mx).toList();
}

/// 見本/録音 共通の“見やすい波形”に加工（5ms刻み）
List<double> processWaveformUniform(WavePCM wav,
    {int windowMs = 10, int hopMs = 5}) {
  final r = _rms(wav.samples,
      sampleRate: wav.sampleRate, windowMs: windowMs, hopMs: hopMs);
  final c = _compress(r, gamma: 0.6);
  final s = _ema(c, alpha: 0.25);
  final n = _normalize01(s);
  return n; // 5ms刻み（= 200サンプル/秒）
}

/// ─────────────────────────────────────────────────────────
/// 既存API名の互換レイヤ（以前は平均&100Hzだったが、今回は200Hz）
/// 画面描画用にそのまま amplitudes として使える
/// ─────────────────────────────────────────────────────────
Future<List<double>> extractWaveform(File file) async {
  final wav = await decodeWaveFromFile(file);
  return processWaveformUniform(wav); // 5ms刻み（200/秒）
}

Future<List<double>> extractWaveformFromAssets(String assetPath) async {
  final wav = await decodeWaveFromAssets(assetPath);
  return processWaveformUniform(wav); // 5ms刻み（200/秒）
}

/// 必要なら、描画幅に合わせたリサンプル（線形）
List<double> resampleForDisplay(List<double> data, int targetLength) {
  if (data.isEmpty || targetLength <= 0) return const [];
  if (data.length == targetLength) return List.of(data);

  final out = <double>[];
  for (int i = 0; i < targetLength; i++) {
    final t = i * (data.length - 1) / (targetLength - 1);
    final i0 = t.floor();
    final i1 = math.min(i0 + 1, data.length - 1);
    final frac = t - i0;
    out.add(data[i0] * (1 - frac) + data[i1] * frac);
  }
  return out;
}
