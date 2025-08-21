import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_snapshot.dart';

class HistoryStore {
  static const _key = 'score_history_v1';
  static const _cap = 100; // 履歴最大件数

  static Future<List<ScoreSnapshot>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(ScoreSnapshot.fromJson)
          .where((e) => e.isValid)
          .toList();
      return list;
    } catch (_) {
      // 破損時はクリアして空配列返す（クラッシュさせない）
      await sp.remove(_key);
      return [];
    }
  }

  static Future<void> saveAll(List<ScoreSnapshot> list) async {
    final sp = await SharedPreferences.getInstance();
    final safe = list.take(_cap).map((e) => e.toJson()).toList();
    await sp.setString(_key, jsonEncode(safe));
  }

  static Future<void> append(ScoreSnapshot snap) async {
    final list = await load();
    list.insert(0, snap);
    await saveAll(list);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
