import 'package:flutter/material.dart';

typedef WordLookup = Future<List<String>> Function(String word);

Future<void> showWordMeaningSheet(
  BuildContext context, {
  required String word,
  required WordLookup lookup,
  VoidCallback? onPlayOnce, // ← 単語ワンショット再生
}) async {
  final defs = await lookup(word);
  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          bool isPlaying = false; // 見た目だけのフラグ（任意）

          final notFound = defs.isEmpty;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(word,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (onPlayOnce != null)
                      IconButton(
                        tooltip: 'この単語を再生',
                        icon: Icon(
                            // ignore: dead_code
                            isPlaying ? Icons.volume_up : Icons.play_arrow),
                        onPressed: () {
                          // ★ シートは閉じない！再生だけトリガー
                          onPlayOnce();
                          setState(() => isPlaying = true);
                          // 再生完了時に見た目を戻したいなら、
                          // 親側でコールバックをもう1本用意して呼んでもOK
                        },
                      ),
                  ]),
                  const SizedBox(height: 8),
                  if (notFound)
                    const Text('見つかりませんでした',
                        style: TextStyle(color: Colors.grey))
                  else
                    ...defs.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child:
                              Text('・$e', style: const TextStyle(fontSize: 16)),
                        )),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
