import 'package:flutter/material.dart';

class SpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final void Function(double) onSpeedSelected;

  const SpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    final speeds = [0.6, 0.75, 1.0, 1.2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: speeds.map((speed) {
        final isSelected = speed == currentSpeed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton(
            onPressed: () => onSpeedSelected(speed),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[400],
              foregroundColor: Colors.white,
            ),
            child: Text('${speed}x'),
          ),
        );
      }).toList(),
    );
  }
}
