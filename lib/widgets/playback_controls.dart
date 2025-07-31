import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_controller.dart';

class PlaybackControls extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsControllerProvider).isDarkMode;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: onRestart,
          color: iconColor,
        ),
        IconButton(
          icon: const Icon(Icons.replay_5),
          onPressed: onSeekBackward,
          color: iconColor,
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 40,
          onPressed: onPlayPauseToggle,
          color: iconColor,
        ),
        IconButton(
          icon: const Icon(Icons.forward_5),
          onPressed: onSeekForward,
          color: iconColor,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRestart,
          color: iconColor,
        ),
      ],
    );
  }
}
