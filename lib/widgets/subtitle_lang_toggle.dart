import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/subtitle_lang_mode.dart';

class SubtitleLangToggle extends ConsumerWidget {
  const SubtitleLangToggle({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(subtitleLangModeProvider);
    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          label: const Text('EN'),
          selected: mode == SubtitleLangMode.en,
          onSelected: (_) => ref
              .read(subtitleLangModeProvider.notifier)
              .set(SubtitleLangMode.en),
        ),
        ChoiceChip(
          label: const Text('JA'),
          selected: mode == SubtitleLangMode.ja,
          onSelected: (_) => ref
              .read(subtitleLangModeProvider.notifier)
              .set(SubtitleLangMode.ja),
        ),
        ChoiceChip(
          label: const Text('EN+JA'),
          selected: mode == SubtitleLangMode.both,
          onSelected: (_) => ref
              .read(subtitleLangModeProvider.notifier)
              .set(SubtitleLangMode.both),
        ),
      ],
    );
  }
}
