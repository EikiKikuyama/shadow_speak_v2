import 'package:flutter/material.dart';
import 'dart:async';
import '../models/material_model.dart';
import '../models/subtitle_segment.dart';
import '../services/audio_player_service.dart';
import '../services/subtitle_loader.dart';
import '../utils/subtitle_utils.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/playback_controls.dart';
import '../widgets/subtitle_display.dart';

class ListeningMode extends StatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  State<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends State<ListeningMode> {
  final AudioPlayerService _audioService = AudioPlayerService();
  String? sampleFilePath;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;

  List<SubtitleSegment> _subtitles = [];
  SubtitleSegment? _currentSubtitle;
  StreamSubscription<Duration>? _positionSubscription;

  String fullText = "";
  int currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSampleAudio();
    _loadSubtitle();

    _positionSubscription = _audioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      final current = getCurrentSubtitle(_subtitles, pos);
      if (current != _currentSubtitle) {
        setState(() {
          _currentSubtitle = current;
        });
      }
    });
  }

  Future<void> _loadSampleAudio() async {
    final path = await _audioService.copyAssetToFile(widget.material.audioPath);
    if (!mounted) return;
    await _audioService.prepareLocalFile(path, _currentSpeed);
    setState(() {
      sampleFilePath = path;
    });
  }

  Future<void> _loadSubtitle() async {
    final filename = widget.material.scriptPath
        .split('/')
        .last
        .replaceAll('.txt', '')
        .replaceAll('.json', '');

    final data = await loadSubtitles(filename);
    setState(() {
      _subtitles = data;

      fullText = _subtitles.map((s) => s.text).join(" ");
    });
  }

  Future<void> _togglePlayPause(bool isPlaying) async {
    if (sampleFilePath == null) return;
    await _audioService.setSpeed(_currentSpeed);
    if (isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.resume();
    }
  }

  Future<void> _reset() async {
    await _audioService.reset();
  }

  @override
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioService.stop(); // 同期で呼ぶ（ここで await しない）
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final subtitleHeight = screenHeight * 0.3;

    final total = _audioService.totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Scaffold(
        backgroundColor: const Color(0xFF001F3F), // 深めの紺色
        appBar: AppBar(
          backgroundColor: const Color(0xFF001F3F), // 深めの紺色
          elevation: 0,
          title:
              const Text('🎧 リスニングモード', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // 👇最上部に追加
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icon.png'), // ←仮画像（差し替え可）
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 波形
                    Container(
                      width: double.infinity,
                      height: 160,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      child: sampleFilePath != null
                          ? ClipRect(
                              child: SampleWaveformWidget(
                                filePath: sampleFilePath!,
                                height: 100,
                                progress: progress,
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),
                    ),

// 👇 追加：波形下に字幕（今は仮で固定1つ）
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          "波形のところだけ字幕表示はここ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // 字幕（全文＋ハイライト対応）
                    Container(
                      height: subtitleHeight,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: _subtitles.isNotEmpty
                              ? RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children:
                                        List.generate(fullText.length, (index) {
                                      final isActive = index ==
                                          currentCharIndex; // 🔥 ハイライト判定
                                      return TextSpan(
                                        text: fullText[index],
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.yellow
                                              : Colors.white,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    "字幕を読み込み中…",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // 👇 下部に固定した再生＆速度ボタン
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: _audioService.isPlayingStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return PlaybackControls(
                        isPlaying: isPlaying,
                        onPlayPauseToggle: () => _togglePlayPause(isPlaying),
                        onRestart: _reset,
                        onSeekForward: () {
                          _audioService.seek(
                              _currentPosition + const Duration(seconds: 5));
                        },
                        onSeekBackward: () {
                          _audioService.seek(
                              _currentPosition - const Duration(seconds: 5));
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SpeedSelector(
                    currentSpeed: _currentSpeed,
                    onSpeedSelected: (speed) {
                      setState(() {
                        _currentSpeed = speed;
                      });
                      _audioService.setSpeed(speed);
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
