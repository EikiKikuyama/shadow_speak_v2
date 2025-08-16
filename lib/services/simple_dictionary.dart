import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SimpleDictionary {
  // 常に非NULL。未指定なら既定パスを使う
  final String assetPath;

  SimpleDictionary({String? assetPath})
      : assetPath = assetPath ?? 'assets/dict/simple_dict.json';

  Map<String, List<String>> _map = {};
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final raw = await rootBundle.loadString(assetPath);
    final m = json.decode(raw) as Map<String, dynamic>;
    _map = m.map((k, v) => MapEntry(_norm(k), List<String>.from(v)));
    _ready = true;
  }

  Future<List<String>> lookup(String word) async {
    if (!_ready) await init(); // 初回タップでも確実にロード
    final w = _norm(word);
    if (w.isEmpty) return [];

    final exact = _map[w];
    if (exact != null) return exact;

    for (final c in _cands(w)) {
      final hit = _map[c];
      if (hit != null) return hit;
    }
    return [];
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r"[^\w'-]"), '');

  Iterable<String> _cands(String w) sync* {
    if (w.endsWith('ing') && w.length > 5) yield w.substring(0, w.length - 3);
    if (w.endsWith('ies') && w.length > 4)
      yield w.substring(0, w.length - 3) + 'y';
    if (w.endsWith('es') && w.length > 4) yield w.substring(0, w.length - 2);
    if (w.endsWith('ed') && w.length > 4) yield w.substring(0, w.length - 2);
    if (w.endsWith('s') && w.length > 3) yield w.substring(0, w.length - 1);
  }
}
