import 'dart:io';
import 'dart:typed_data';

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
