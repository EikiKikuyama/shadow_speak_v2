import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/subtitles_widget.dart';
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
  String subtitleText = '';

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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecording();
      await _audioService.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WavWaveformScreen(
              wavFilePath: path,
              material: widget.material,
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
    }
  }

  Future<void> _resetPlayback() async {
    await _audioService.reset();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final subtitleHeight = screenHeight * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          '🎤 録音モード',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.red : Colors.white,
                    size: 40,
                  ),
                  onPressed: _toggleRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt,
                      size: 32, color: Colors.white),
                  onPressed: _resetPlayback,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: subtitleHeight,
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6E3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SubtitlesWidget(
                    subtitleText: widget.material.scriptPath,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
