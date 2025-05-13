import 'package:flutter/material.dart';
import '../models/material_model.dart';

class OverlappingMode extends StatelessWidget {
  final PracticeMaterial material;

  const OverlappingMode({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 オーバーラッピングモード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Container(
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Text('📈 波形表示（仮）'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.play_arrow, size: 32),
                Icon(Icons.stop, size: 32),
                Icon(Icons.mic, size: 32),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Text(
                  material.scriptPath,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
