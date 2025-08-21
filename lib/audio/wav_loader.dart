// lib/audio/wav_loader.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert'; // ← 追加（候補表示用）

class WavMono {
  final List<double> samples;
  final int sampleRate;
  WavMono(this.samples, this.sampleRate);
}

// 端末ローカルの実ファイルから読む（録音ファイルなど）
Future<WavMono> loadWavAsMonoFloat(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  return _loadWavFromBytes(bytes);
}

// パス補正: 'audio/...' でも 'assets/audio/...' でもOKにする
String _resolveAssetPath(String p) {
  var s = p.trim();
  if (s.startsWith('/')) s = s.substring(1); // 先頭スラッシュ除去
  if (!s.startsWith('assets/')) s = 'assets/$s';
  return s;
}

// アセットから読む（見本音声など）
Future<WavMono> loadWavAssetAsMonoFloat(String assetPath) async {
  final resolved = _resolveAssetPath(assetPath);
  try {
    final bd = await rootBundle.load(resolved);
    return _loadWavFromBytes(bd.buffer.asUint8List());
  } catch (e) {
    // 見つからない・空データ時に候補を出す（デバッグ用）
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson);
      final candidates = manifest.keys
          .where((k) => k.startsWith('assets/audio/'))
          .where((k) => k.toLowerCase().contains(
                resolved.split('/').last.toLowerCase().replaceAll('.wav', ''),
              ))
          .take(8)
          .toList();
      // ログに出す
      // ignore: avoid_print
      print('❌ Asset not found or empty: $resolved');
      if (candidates.isNotEmpty) {
        // ignore: avoid_print
        print('🔎 Similar assets:\n${candidates.join('\n')}');
      }
    } catch (_) {}
    rethrow;
  }
}

// ここが共通の WAV 解析（PCM16 モノラル化）
WavMono _loadWavFromBytes(Uint8List bytes) {
  final data = ByteData.view(bytes.buffer);

  // --- RIFF/WAVE ヘッダ確認 ---
  if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
    throw FormatException('Not a RIFF/WAVE file');
  }

  // ← ここを nullable から「番兵値つき非null」に変更
  int audioFormat = -1;
  int numChannels = 0;
  int sampleRate = 0;
  int bitsPerSample = 0;
  int dataOffset = -1;
  int dataSize = 0;

  int offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = data.getUint32(offset + 4, Endian.little);
    final chunkDataStart = offset + 8;

    if (chunkId == 'fmt ') {
      audioFormat = data.getUint16(chunkDataStart + 0, Endian.little);
      numChannels = data.getUint16(chunkDataStart + 2, Endian.little);
      sampleRate = data.getUint32(chunkDataStart + 4, Endian.little);
      bitsPerSample = data.getUint16(chunkDataStart + 14, Endian.little);
    } else if (chunkId == 'data') {
      dataOffset = chunkDataStart;
      dataSize = chunkSize;
      break;
    }
    offset = chunkDataStart + chunkSize;
  }

  // --- 妥当性チェック（ここで番兵値を弾く） ---
  if (audioFormat != 1) {
    throw UnsupportedError('Only PCM (format=1) supported');
  }
  if (bitsPerSample != 16) {
    throw UnsupportedError('Only 16-bit PCM supported');
  }
  if (numChannels <= 0 || sampleRate <= 0 || dataOffset < 0 || dataSize <= 0) {
    throw FormatException('Invalid WAV structure');
  }

  final bytesPerSample = bitsPerSample ~/ 8; // ← もう int なので '!' 不要
  final frameCount = dataSize ~/ (bytesPerSample * numChannels);

  final out = List<double>.filled(frameCount, 0.0);
  var read = dataOffset;
  for (int i = 0; i < frameCount; i++) {
    double acc = 0.0;
    for (int ch = 0; ch < numChannels; ch++) {
      final s = data.getInt16(read, Endian.little);
      acc += s / 32768.0;
      read += 2;
    }
    out[i] = acc / numChannels;
  }

  return WavMono(out, sampleRate);
}
