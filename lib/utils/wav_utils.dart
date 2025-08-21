import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

/// ファイルからWAVのバイナリを読み込む（録音ファイル用）
Future<Uint8List> loadWavFile(String filePath) async {
  final file = File(filePath);
  return await file.readAsBytes();
}

/// WAVのバイナリデータから振幅リストを抽出
List<double> extractAmplitudesFromWav(Uint8List bytes) {
  const headerSize = 44; // WAVのヘッダー（リトルエンディアン）
  final audioData = bytes.sublist(headerSize);
  final amplitudes = <double>[];

  for (int i = 0; i < audioData.length - 1; i += 2) {
    final sample = (audioData[i + 1] << 8) | audioData[i]; // 16bit PCM
    double normalized = sample.toSigned(16) / 32768.0;
    amplitudes.add(normalized.abs()); // 絶対値にすることで上下対称に
  }

  return amplitudes;
}

double _toDb(double v) => 20 * (math.log(v.clamp(1e-9, 1.0)) / math.ln10);

List<double> applyNoiseGate(
  List<double> s, {
  double openDb = -42, // 開くしきい値
  double closeDb = -48, // 閉じるしきい値（ヒステリシス）
  int holdMs = 60, // 開いた後のホールド時間
  int hopMs = 5, // 200fps なら 5ms
}) {
  if (s.isEmpty) return const [];
  final out = List<double>.from(s);
  final holdFrames = (holdMs / hopMs).round().clamp(0, 1000);
  var open = false;
  var hold = 0;

  for (int i = 0; i < out.length; i++) {
    final db = _toDb(out[i]); // out[i] は 0..1 を想定（rms/正規化後）
    if (open) {
      if (db < closeDb) {
        if (hold-- <= 0) open = false;
      } else {
        hold = holdFrames;
      }
    } else {
      if (db > openDb) {
        open = true;
        hold = holdFrames;
      }
    }
    if (!open) out[i] = 0.0;
  }
  return out;
}

// 0..1 の200fps系列に対し、しきい値 level 未満の「短いON島」を 0 に潰す
List<double> squelchTinyIslands(List<double> s,
    {int minOnMs = 100, double level = 0.02}) {
  if (s.isEmpty) return s;
  final out = List<double>.from(s);
  final minFrames = (minOnMs / 5).round(); // 200fps → 5ms/フレーム

  int i = 0;
  while (i < out.length) {
    // “ON”とみなす: level 以上
    if (out[i] >= level) {
      int j = i;
      while (j < out.length && out[j] >= level) j++;
      final len = j - i;

      // 島が短ければ 0 に潰す
      if (len < minFrames) {
        for (int k = i; k < j; k++) out[k] = 0.0;
      }
      i = j;
    } else {
      i++;
    }
  }
  return out;
}

// s: 0..1 の200fps配列
List<double> subtractGlobalFloor(List<double> s,
    {double q = 0.12, double margin = 1.10}) {
  if (s.isEmpty) return s;
  final sorted = [...s]..sort();
  final idx = (sorted.length * q).floor().clamp(0, sorted.length - 1);
  final floor = (sorted[idx] * margin).clamp(0.0, 1.0);
  // 下駄を引いて負なら0
  return s.map((v) {
    final x = v - floor;
    return x <= 0 ? 0.0 : x;
  }).toList();
}

// 最後の微小値をゼロに固定（残像の完全除去）
List<double> autoZeroFloor(List<double> s,
    {double quantile = 0.985, double margin = 1.05}) {
  if (s.isEmpty) return s;
  final sorted = [...s]..sort();
  final idx = (sorted.length * quantile).floor().clamp(0, sorted.length - 1);
  final th = (sorted[idx] * margin).clamp(0.0, 1.0);
  return s.map((v) => v < th ? 0.0 : v).toList();
}

// デバッグ（任意）
void debugQuietStats(String tag, List<double> s) {
  final sorted = [...s]..sort();
  double q(double p) =>
      sorted[(sorted.length * p).floor().clamp(0, sorted.length - 1)];
  // 下側の分布を見たいので 0.02/0.1/0.2 を見る
  final p02 = q(0.02), p10 = q(0.10), p20 = q(0.20);
  print(
      '[$tag] p02=${p02.toStringAsFixed(4)} p10=${p10.toStringAsFixed(4)} p20=${p20.toStringAsFixed(4)}');
}
