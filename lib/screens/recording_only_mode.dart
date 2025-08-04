import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subtitle_loader.dart';
import '../widgets/custom_app_bar.dart';
import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../screens/wav_waveform_screen.dart';
import '../settings/settings_controller.dart';

class RecordingOnlyMode extends ConsumerStatefulWidget {
  final PracticeMaterial material;

  const RecordingOnlyMode({super.key, required this.material});

  @override
  ConsumerState<RecordingOnlyMode> createState() => _RecordingOnlyModeState();
}

class _RecordingOnlyModeState extends ConsumerState<RecordingOnlyMode> {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _audioService = AudioPlayerService();

  bool _isRecording = false;
  bool _isResetting = false;
  int? countdownValue;
  String subtitleText = '';
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    try {
      final filename = widget.material.scriptPath
          .replaceFirst('assets/subtitles/', '') // パス先頭だけ削除
          .replaceAll('.json', '')
          .replaceAll('.txt', '');

      final data = await loadSubtitles(filename);
      if (!mounted) return;
      setState(() {
        subtitleText = data.map((s) => s.text).join('\n');
      });
    } catch (e) {
      debugPrint('❌ 字幕読み込み失敗: $e');
      setState(() {
        subtitleText = '字幕の読み込みに失敗しました。';
      });
    }
  }

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
  }

  Future<void> _startCountdownAndRecord() async {
    if (_isRecording) return;

    setState(() {
      countdownValue = 3;
      _isResetting = false;
    });

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _isResetting) return;
      setState(() => countdownValue = i - 1);
    }

    if (!mounted || _isResetting) return;

    setState(() {
      countdownValue = null;
      _isRecording = true;
    });

    _startRecordingTimer();

    final savePath = await _recorder.getSavePath(
      level: widget.material.level,
      title: widget.material.title,
    );

    await _recorder.startRecording(
      path: savePath,
      level: widget.material.level,
      title: widget.material.title,
    );
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecording();
    _stopRecordingTimer();

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
  }

  Future<void> _reset() async {
    setState(() {
      _isResetting = true;
      _isRecording = false;
      countdownValue = null;
      _recordingSeconds = 0;
    });
    _stopRecordingTimer();
    await _audioService.stop();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    _stopRecordingTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);
    final isDark = settingsController.isDarkMode;
    final backgroundColor =
        isDark ? const Color(0xFF001042) : const Color(0xFFF4F1FA);
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = Colors.red;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final boxColor = isDark ? Colors.white10 : Colors.grey[200];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: 'レコーディングモード',
        backgroundColor: backgroundColor,
        titleColor: textColor,
        iconColor: textColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '下の文章を声に出して録音してみよう',
              style: TextStyle(
                fontSize: 18,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? '$_recordingSeconds 秒'
                  : countdownValue != null
                      ? '録音開始まで: $countdownValue'
                      : '録音は停止中',
              style: TextStyle(
                fontSize: 22,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: boxColor,
              child: Center(
                child: Text(
                  'リアルタイム波形（後で追加）',
                  style: TextStyle(color: subTextColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _isRecording
                        ? _stopRecording()
                        : _startCountdownAndRecord();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 4),
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: Icon(Icons.mic, color: textColor, size: 40),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: Icon(Icons.restart_alt, size: 36, color: textColor),
                  onPressed: _reset,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
