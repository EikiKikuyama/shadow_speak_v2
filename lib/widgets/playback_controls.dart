import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onRestart;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPauseToggle,
    required this.onRestart,
    required this.onSeekForward,
    required this.onSeekBackward,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: onRestart,
        ),
        IconButton(
          icon: const Icon(Icons.replay_5),
          onPressed: onSeekBackward,
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 40,
          onPressed: onPlayPauseToggle,
        ),
        IconButton(
          icon: const Icon(Icons.forward_5),
          onPressed: onSeekForward,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRestart,
        ),
      ],
    );
  }
}
