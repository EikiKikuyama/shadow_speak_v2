import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/audio_player_service.dart';

class ListeningMode extends StatefulWidget {
  final PracticeMaterial material;

  const ListeningMode({super.key, required this.material});

  @override
  State<ListeningMode> createState() => _ListeningModeState();
}

class _ListeningModeState extends State<ListeningMode> {
  final _audioService = AudioPlayerService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎧 リスニングモード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 波形領域（仮）
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

            // 機能アイコン行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 32),
                  onPressed: () async {
                    await _audioService.play(widget.material.audioPath);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.pause, size: 32),
                  onPressed: () async {
                    await _audioService.pause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32),
                  onPressed: () async {
                    await _audioService.reset();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // スクリプト表示（今は path 表示、後で本文に差し替え）
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Text(
                  widget.material.scriptPath,
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
