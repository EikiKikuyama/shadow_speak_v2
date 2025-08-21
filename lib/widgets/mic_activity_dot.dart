import 'package:flutter/material.dart';
import '../utils/mic_amplitude_service.dart';

class MicActivityDot extends StatelessWidget {
  final MicAmplitudeService mic;
  final bool enabled;
  final double threshold;
  final double size;
  final Color idleColor;
  final Color activeColor;

  const MicActivityDot({
    super.key,
    required this.mic,
    required this.enabled,
    this.threshold = 0.08,
    this.size = 12,
    this.idleColor = const Color(0x33FFFFFF),
    this.activeColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      // mic.start()/stop() は親で制御する
      stream: mic.amplitudeStream,
      initialData: 0.0,
      builder: (context, snap) {
        final amp = (snap.data ?? 0.0);
        final isHot = enabled && amp >= threshold;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isHot ? activeColor : idleColor,
            shape: BoxShape.circle,
            boxShadow: isHot
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.35),
                      blurRadius: size * 0.9,
                      spreadRadius: size * 0.15,
                    )
                  ]
                : const [],
          ),
        );
      },
    );
  }
}
