import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← 字幕読み込みに必要
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/realtime_waveform_widget.dart';
import '../widgets/subtitles_widget.dart'; // ← 字幕ウィジェット
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
  String subtitleText = ''; // ← 字幕用

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    try {
      final text = await rootBundle.loadString(widget.material.scriptPath);
      if (!mounted) return;
      setState(() {
        subtitleText = text;
      });
    } catch (e) {
      debugPrint('❌ 字幕読み込み失敗: $e');
      setState(() {
        subtitleText = '字幕の読み込みに失敗しました。';
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecording();
      await _audioService.stop();
      setState(() {
        _isRecording = false;
      });
      debugPrint('🎤 録音停止: $path');

      if (path != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WavWaveformScreen(
              wavFilePath: path,
              material: widget.material, // ← ここを追加！
            ),
          ),
        );
      }
    } else {
      await _audioService.stop();
      await _recorder.startRecording();
      setState(() {
        _isRecording = true;
      });
      debugPrint('🎤 録音開始');
    }
  }

  Future<void> _resetPlayback() async {
    await _audioService.reset();
    debugPrint('🔄 リセット');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 録音モード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: RealtimeWaveformWidget(
                amplitudeStream: _recorder.amplitudeStream,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
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
                  icon: const Icon(Icons.restart_alt, size: 32),
                  onPressed: _resetPlayback,
                ),
              ],
            ),
            const SizedBox(height: 20),
// ✅ 字幕だけスクロール可能に
            Container(
              height: 300,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child:
                    SubtitlesWidget(subtitleText: widget.material.scriptPath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
