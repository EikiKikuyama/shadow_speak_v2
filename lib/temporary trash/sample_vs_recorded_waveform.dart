import 'package:flutter/material.dart';

class SampleVsRecordedWaveform extends StatelessWidget {
  final List<double> sampleData;
  final List<double> recordedData;

  const SampleVsRecordedWaveform({
    super.key,
    required this.sampleData,
    required this.recordedData,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 100),
      painter: _WaveformPainter(
        sampleData: sampleData,
        recordedData: recordedData,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> sampleData;
  final List<double> recordedData;

  _WaveformPainter({
    required this.sampleData,
    required this.recordedData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintSample = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5;

    final paintRecorded = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5;

    final centerY = size.height / 2;
    final spacing = size.width / sampleData.length;

    for (int i = 0; i < sampleData.length; i++) {
      final x = i * spacing;
      final sampleY = centerY - sampleData[i] * 40;
      canvas.drawLine(Offset(x, centerY), Offset(x, sampleY), paintSample);
    }

    for (int i = 0; i < recordedData.length; i++) {
      final x = i * spacing;
      final recordedY = centerY + recordedData[i] * 40;
      canvas.drawLine(Offset(x, centerY), Offset(x, recordedY), paintRecorded);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
