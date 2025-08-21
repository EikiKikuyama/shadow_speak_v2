import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';

/// 200fps(=5ms hop)の正規化振幅(0..1)を吐く軽量サービス
class MicAmplitudeService {
  final _rec = AudioRecorder();

  StreamSubscription<Uint8List>? _pcmSub;

  // 0..1 のストリーム（200fps想定）
  final _controller = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _controller.stream;

  // 互換エイリアス（古い呼び出しを吸収）
  Stream<double> get seriesStream => amplitudeStream;
  Stream<double> get stream => amplitudeStream;

  // ---- パラメータ ----
  final int sampleRate; // 44100
  final int rmsWinMs; // 10ms
  final int hopMs; // 5ms -> 200fps
  final double emaAlpha; // 0.18
  final double ngOpenDb; // -40
  final double ngCloseDb; // -52
  final int ngHoldMs; // 100
  final double gateDb; // 既定 -46（使うなら）

  MicAmplitudeService({
    this.sampleRate = 44100,
    this.rmsWinMs = 10,
    this.hopMs = 5,
    this.emaAlpha = 0.18,
    this.ngOpenDb = -40,
    this.ngCloseDb = -52,
    this.ngHoldMs = 100,
    this.gateDb = -46,
  });

  // 内部状態
  final List<int> _ring = <int>[];
  int _win = 0;
  int _hop = 0;
  int _holdFrames = 0;

  double _ema = 0.0;
  double _softP95 = 0.1;

  bool _gateOpen = false;
  int _gateHoldFrames = 0;

  bool _started = false;

  Future<void> _configureSessionForDuplex() async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        // iOS
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        // Set ではなく “ビット結合した1つの値” を渡す
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers |
                AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth,
        // Android
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _configureSessionForDuplex();

    _win = ((sampleRate * rmsWinMs) / 1000).round(); // 44100*0.01=441
    _hop = ((sampleRate * hopMs) / 1000).round(); // 44100*0.005=220
    _holdFrames = (ngHoldMs / hopMs).round(); // 100/5=20

    if (!await _rec.hasPermission()) {
      _started = false;
      throw Exception('Microphone permission not granted');
    }

    // ★ streaming は AAC 非対応。必ず PCM16bits を指定！
    final stream = await _rec.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    _pcmSub = stream.listen((chunk) {
      // Int16LE へ変換してリングに積む
      final bd = ByteData.sublistView(chunk);
      for (int i = 0; i + 1 < chunk.length; i += 2) {
        final s = bd.getInt16(i, Endian.little);
        _ring.add(s);
      }
      _processFrames();
    });
  }

  Future<void> stop() async {
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _rec.isRecording()) {
      await _rec.stop();
    }
    _ring.clear();
    _ema = 0.0;
    _softP95 = 0.1;
    _gateOpen = false;
    _gateHoldFrames = 0;
    _started = false;
  }

  void dispose() {
    _controller.close();
  }

  // ---- コア処理 ----
  void _processFrames() {
    while (_ring.length >= _win) {
      // 10ms RMS
      double acc = 0.0;
      for (int i = 0; i < _win; i++) {
        final v = _ring[i] / 32768.0;
        acc += v * v;
      }
      final rms = math.sqrt(acc / _win); // 0..1

      // EMA（平滑化）
      _ema = emaAlpha * rms + (1 - emaAlpha) * _ema;

      // Soft P95（ダイナミック正規化）
      final peakAlpha = (_ema > _softP95) ? 0.02 : 0.002;
      _softP95 += peakAlpha * (_ema - _softP95);
      final denom = (_softP95 <= 1e-6) ? 1e-6 : _softP95;
      double norm = (_ema / (denom * 1.15)).clamp(0.0, 1.0);

      // ノイズゲート（開閉+ホールド）
      final db = _linToDb(norm);
      if (_gateOpen) {
        if (db <= ngCloseDb) {
          _gateHoldFrames = math.max(0, _gateHoldFrames - 1);
          if (_gateHoldFrames == 0) _gateOpen = false;
        } else {
          _gateHoldFrames = _holdFrames;
        }
      } else {
        if (db >= ngOpenDb) {
          _gateOpen = true;
          _gateHoldFrames = _holdFrames;
        }
      }
      if (!_gateOpen) norm = 0.0;

      // 5ms (=hop) ごとに 1 フレームを出力
      _controller.add(norm);

      // ホップ分を捨てて前進
      final remove = math.min(_hop, _ring.length);
      _ring.removeRange(0, remove);
    }
  }

  static double _linToDb(double lin) {
    if (lin <= 1e-6) return -120.0;
    return 20.0 * math.log(lin) / math.ln10; // dBFS
  }
}
