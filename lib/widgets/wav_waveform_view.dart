import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../widgets/sample_waveform_widget.dart';
import '../widgets/recorded_waveform_widget.dart';

class WavWaveformView extends StatefulWidget {
  final String sampleAssetPath;
  final String recordedFilePath;
  final AudioPlayerService audioPlayerService;
  final double playbackSpeed;

  const WavWaveformView({
    super.key,
    required this.sampleAssetPath,
    required this.recordedFilePath,
    required this.audioPlayerService,
    required this.playbackSpeed,
  });

  @override
  State<WavWaveformView> createState() => _WavWaveformViewState();
}

class _WavWaveformViewState extends State<WavWaveformView> {
  Duration? _audioDuration;
  Duration _currentPosition = Duration.zero;
  late final Stream<Duration> _positionStream;

  @override
  void initState() {
    super.initState();
    _loadAudioDuration();

    // 再生準備と開始
    widget.audioPlayerService.prepareAndPlayLocalFile(
      widget.recordedFilePath,
      widget.playbackSpeed,
    );

    // 位置更新リスナー
    _positionStream = widget.audioPlayerService.positionStream;
    _positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
    });
  }

  Future<void> _loadAudioDuration() async {
    final duration =
        await widget.audioPlayerService.getDuration(widget.recordedFilePath);
    if (!mounted) return;
    setState(() => _audioDuration = duration);
  }

  @override
  Widget build(BuildContext context) {
    if (_audioDuration == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double progress =
        _currentPosition.inMilliseconds / _audioDuration!.inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        SampleWaveformWidget(
          filePath: widget.sampleAssetPath, // ← 修正済み
          height: 100,
          progress: 0.0, // ※必要なら `progress` にしてもOK
        ),
        const SizedBox(height: 32),
        RecordedWaveformWidget(
          filePath: widget.recordedFilePath,
          audioDuration: _audioDuration!,
          height: 100,
          progress: progress,
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.audioPlayerService.dispose();
    super.dispose();
  }
}
