import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/realtime_waveform_widget.dart';
import '../screens/wav_waveform_screen.dart';

class RecordingOnlyMode extends StatefulWidget {
  final PracticeMaterial material;

  const RecordingOnlyMode({super.key, required this.material});

  @override
  State<RecordingOnlyMode> createState() => _RecordingOnlyModeState();
}

class _RecordingOnlyModeState extends State<RecordingOnlyMode> {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _audioService = AudioPlayerService();

  bool _isRecording = false;
  String? _recordedPath;

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecording();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      debugPrint('🎤 録音停止: $path');

      // 🔥 波形表示画面に遷移（追加部分）
      if (path != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WavWaveformScreen(wavFilePath: path),
          ),
        );
      }
    } else {
      await _recorder.startRecording();
      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
      debugPrint('🎤 録音開始');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedPath != null) {
      await _audioService.playLocalFile(_recordedPath!);
      debugPrint('▶️ 再生: $_recordedPath');
    } else {
      debugPrint('⚠️ 再生ファイルがありません');
    }
  }

  Future<void> _stopPlayback() async {
    await _audioService.stop();
    debugPrint('⏹ 再生停止');
  }

  Future<void> _resetPlayback() async {
    await _audioService.reset();
    debugPrint('🔄 リセット');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎙 録音モード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 仮の波形表示
            SizedBox(
              height: 150,
              width: double.infinity,
              child: RealtimeWaveformWidget(
                amplitudeStream: _recorder.amplitudeStream,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),

            // アイコンボタン4つ（録音・再生・停止・リセット）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.red : Colors.black,
                    size: 32,
                  ),
                  onPressed: _toggleRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 32),
                  onPressed: _playRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.pause, size: 32),
                  onPressed: _stopPlayback,
                ),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32),
                  onPressed: _resetPlayback,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // スクリプト表示（今は path 表示、後で本文に差し替え）
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Text(
                  widget.material.scriptPath,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            if (_recordedPath != null) ...[
              const SizedBox(height: 20),
              Text('📁 録音ファイル: $_recordedPath'),
            ],
          ],
        ),
      ),
    );
  }
}
