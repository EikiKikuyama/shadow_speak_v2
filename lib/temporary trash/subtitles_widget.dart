import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 必須！

class SubtitlesWidget extends StatelessWidget {
  final String subtitleText; // ← 実際には「ファイルパス」

  const SubtitlesWidget({
    super.key,
    required this.subtitleText,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(subtitleText),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text(
            '⚠️ 字幕の読み込みに失敗しました',
            style: TextStyle(color: Colors.red),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7), // ✅ 完全互換

              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              snapshot.data!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }
}
