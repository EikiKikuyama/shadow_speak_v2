import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/subtitle_loader.dart';
import '../widgets/custom_app_bar.dart';

import '../models/material_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../screens/wav_waveform_screen.dart';
import 'dart:io'; // ← FileやDirectoryを使っている場合

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _isResetting = false;
  int? countdownValue;
  String subtitleText = '';

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    try {
      final filename = widget.material.scriptPath
          .split('/')
          .last
          .replaceAll('.txt', '')
          .replaceAll('.json', '');

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

    // ✅ level と title を渡すように修正
    final savePath = await _recorder.getSavePath(
      level: widget.material.level,
      title: widget.material.title,
    );

// 👇 ここにログを追加
    debugPrint('🎯 渡されたlevel: ${widget.material.level}');
    debugPrint('🎯 渡されたtitle: ${widget.material.title}');
    debugPrint('🎯 savePath: $savePath');

    await _recorder.startRecording(
      path: savePath,
      level: widget.material.level,
      title: widget.material.title,
    );
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecording();
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
    });
    await _audioService.stop();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001042),
      appBar: const CustomAppBar(
        title: 'レコーディングモード',
        backgroundColor: Color(0xFF001042),
        titleColor: Colors.white,
        iconColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (countdownValue != null)
              Text(
                countdownValue == 0 ? 'Go!' : countdownValue.toString(),
                style: const TextStyle(
                  fontSize: 80,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
                      border: Border.all(color: Colors.red, width: 4),
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(Icons.restart_alt,
                      size: 36, color: Colors.white),
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
