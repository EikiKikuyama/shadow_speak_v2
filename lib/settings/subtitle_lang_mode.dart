import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubtitleLangMode { en, ja, both }

String _modeToStr(SubtitleLangMode m) => m == SubtitleLangMode.ja
    ? 'ja'
    : (m == SubtitleLangMode.both ? 'both' : 'en');
SubtitleLangMode _strToMode(String? s) {
  switch (s) {
    case 'ja':
      return SubtitleLangMode.ja;
    case 'both':
      return SubtitleLangMode.both;
    default:
      return SubtitleLangMode.en;
  }
}

class SubtitleLangModeController extends StateNotifier<SubtitleLangMode> {
  SubtitleLangModeController() : super(SubtitleLangMode.en) {
    _load();
  }
  static const _key = 'subtitle_lang_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _strToMode(prefs.getString(_key));
  }

  Future<void> set(SubtitleLangMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToStr(mode));
  }
}

final subtitleLangModeProvider =
    StateNotifierProvider<SubtitleLangModeController, SubtitleLangMode>(
  (ref) => SubtitleLangModeController(),
);
