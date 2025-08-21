// lib/screens/recording_history_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_controller.dart';
import '../widgets/custom_app_bar.dart';

class RecordingHistoryScreen extends ConsumerStatefulWidget {
  const RecordingHistoryScreen({super.key});

  @override
  ConsumerState<RecordingHistoryScreen> createState() =>
      _RecordingHistoryScreenState();
}

class _RecordingHistoryScreenState extends ConsumerState<RecordingHistoryScreen>
    with WidgetsBindingObserver {
  // ==== 設定 ===============================================================
  // 「Documents/shadow_speak/recordings だけを対象」にする安全運転モード
  static const bool kStrictDocsOnly = true;

  // ==== 状態 ===============================================================
  final _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  bool _loading = false;

  List<Map<String, dynamic>> recordings = [];
  Set<String> favoritePaths = {};

  // ==== ライフサイクル =====================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFavorites().then((_) => _loadRecordings());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRecordings();
    }
  }

  // ==== お気に入り =========================================================
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoritePaths = prefs.getStringList('favorites')?.toSet() ?? {};
    if (mounted) setState(() {});
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favoritePaths.toList());
  }

  void _toggleFavorite(int index) async {
    final path = recordings[index]['path'] as String;
    setState(() {
      final now = !(recordings[index]['isFavorite'] as bool);
      recordings[index]['isFavorite'] = now;
      if (now) {
        favoritePaths.add(path);
      } else {
        favoritePaths.remove(path);
      }
    });
    await _saveFavorites();
  }

  // ==== 収集：検索 & 重複排除 ==============================================
  int _pathPrefScore(String path) {
    final l = path.toLowerCase();
    if (l.contains('/documents/shadow_speak/recordings')) return 5;
    if (l.contains('/documents')) return 4;
    if (l.contains('/library/application support')) return 3;
    if (l.contains('/library')) return 2;
    if (l.contains('/tmp') ||
        l.contains('/temporary') ||
        l.contains('/caches')) {
      return 1;
    }
    return 0;
  }

  bool _isCachey(String lower) {
    return lower.contains('/tmp') ||
        lower.contains('/temporary') ||
        lower.contains('/caches') ||
        lower.contains('/splashboard');
  }

  Future<List<File>> _collectAudioFiles() async {
    final docs = await getApplicationDocumentsDirectory();

    final roots = <Directory>[
      Directory(p.join(docs.path, 'shadow_speak', 'recordings')),
    ];

    if (!kStrictDocsOnly) {
      final app = await getApplicationSupportDirectory();
      Directory? lib;
      try {
        lib = await getLibraryDirectory();
      } catch (_) {}
      final tmp = await getTemporaryDirectory();
      roots.addAll([
        Directory(p.join(docs.path, 'shadow_speak')),
        docs,
        if (lib != null) lib,
        app,
        tmp,
      ]);
    }

    const exts = ['.wav', '.m4a', '.aac', '.mp3', '.caf'];
    final Set<String> seen = {};
    final List<File> out = [];

    for (final root in roots) {
      if (!await root.exists()) continue;
      for (final e in root.listSync(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final lower = e.path.toLowerCase();
        if (!exts.any((x) => lower.endsWith(x))) continue;
        if (_isCachey(lower)) continue;
        try {
          if (await e.length() == 0) continue;
        } catch (_) {
          continue;
        }
        if (seen.add(e.path)) out.add(e);
      }
    }
    return out;
  }

  String _logicalKey(File f) {
    final base = p.basenameWithoutExtension(f.path);
    final parts = base.split('__');
    if (parts.length >= 3) {
      // level__title__timestamp をキーに
      return '${parts[0].toLowerCase()}::${parts[1].toLowerCase()}::${parts[2]}';
    }
    return base.toLowerCase();
  }

  List<File> _dedupeByLogicalId(List<File> files) {
    final Map<String, File> best = {};
    final Map<String, FileStat> cache = {};
    FileStat st(File f) => cache[f.path] ??= f.statSync();

    for (final f in files) {
      final key = _logicalKey(f);
      final prev = best[key];
      if (prev == null) {
        best[key] = f;
      } else {
        final sNew = _pathPrefScore(f.path);
        final sOld = _pathPrefScore(prev.path);
        final a = st(f), b = st(prev);
        final better = (sNew > sOld) ||
            (sNew == sOld && a.size > b.size) ||
            (sNew == sOld &&
                a.size == b.size &&
                a.modified.isAfter(b.modified));
        if (better) best[key] = f;
      }
    }
    return best.values.toList();
  }

  // ==== サイドカー（score/stt） ===========================================
  Future<Map<String, dynamic>?> _readJsonIfExists(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  String _convertLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'starter':
        return 'Starter（〜50語）';
      case 'basic':
        return 'Basic（〜80語）';
      case 'intermediate':
        return 'Intermediate（〜100語）';
      case 'upper':
        return 'Upper（〜130語）';
      case 'advanced':
        return 'Advanced（〜150語）';
      default:
        return '未設定';
    }
  }

  String _inferLevelFromPath(String path) {
    final segs = p.split(path).map((s) => s.toLowerCase()).toList();
    if (segs.any((s) => s.contains('starter'))) return 'Starter（〜50語）';
    if (segs.any((s) => s.contains('basic'))) return 'Basic（〜80語）';
    if (segs.any((s) => s.contains('intermediate'))) {
      return 'Intermediate（〜100語）';
    }
    if (segs.any((s) => s.contains('upper'))) return 'Upper（〜130語）';
    if (segs.any((s) => s.contains('advanced'))) return 'Advanced（〜150語）';
    return '未設定';
  }

  Future<Map<String, dynamic>> _hydrateFromSidecars(
      Map<String, dynamic> item) async {
    final path = item['path'] as String;

    // score.json 優先
    final score = await _readJsonIfExists('$path.score.json');
    if (score != null) {
      final overall = (score['overall'] is num)
          ? (score['overall'] as num).toDouble()
          : null;
      if (overall != null) item['score'] = overall.round();

      final lg = (score['levelGuess'] ?? '').toString();
      final tg = (score['titleGuess'] ?? '').toString();
      if ((item['level'] as String).contains('未設定') && lg.isNotEmpty) {
        item['level'] = lg;
      }
      if ((item['title'] as String).contains('未設定') && tg.isNotEmpty) {
        item['title'] = tg;
      }
    }

    // stt.json の whisperScore を最終フォールバックに
    if (item['score'] == null || (item['score'] as num) <= 0) {
      final stt = await _readJsonIfExists('$path.stt.json');
      if (stt != null && stt['whisperScore'] is num) {
        item['score'] = (stt['whisperScore'] as num).round();
      }
    }

    item['score'] ??= 70;
    return item;
  }

  // ==== 読み込み ===========================================================
  Future<void> _loadRecordings() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final collected = await _collectAudioFiles();
      final unique = _dedupeByLogicalId(collected);

      final rough = unique.map((file) {
        final stat = file.statSync();
        final base = p.basenameWithoutExtension(file.path);

        String level = '未設定';
        String title = '未設定';

        final parts = base.split('__');
        if (parts.length >= 3) {
          level = _convertLevel(parts[0]);
          title = parts[1].replaceAll('-', ' ').trim();
        }
        if (level == '未設定') {
          level = _inferLevelFromPath(file.path);
        }

        return {
          'title': title,
          'level': level,
          'path': file.path,
          'score': null,
          'date': stat.modified,
          'isFavorite': favoritePaths.contains(file.path),
        };
      }).toList();

      final hydrated = await Future.wait(rough.map(_hydrateFromSidecars));
      hydrated.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          recordings = hydrated.take(100).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('履歴の読み込みに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==== 再生 ===============================================================
  Future<void> _playRecording(String path) async {
    try {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 120));
      final f = File(path);
      if (!await f.exists() || (await f.length()) < 1024) {
        throw 'ファイルが破損/移動されています';
      }
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('再生に失敗しました: $e')));
    }
  }

  // ==== UI ================================================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;
    final backgroundColor =
        isDarkMode ? const Color(0xFF102542) : Colors.purple[50];
    final appBarColor =
        isDarkMode ? const Color(0xFF0C1A3E) : const Color(0xFFF3F0FA);
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '録音履歴',
        backgroundColor: appBarColor,
        titleColor: titleColor,
        iconColor: iconColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: '更新',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : recordings.isEmpty
              ? Center(
                  child:
                      Text('録音が見つかりません。', style: TextStyle(color: titleColor)),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecordings,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final item = recordings[index];
                      final title = item['title'] as String;
                      final level = item['level'] as String;
                      final path = item['path'] as String;
                      final score = item['score'] as int? ?? 0;
                      final date = item['date'] as DateTime;
                      final fav = item['isFavorite'] as bool;

                      return Card(
                        color: Colors.white,
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          title: Text(
                            'レベル: $level  /  教材: ${title.isEmpty ? '未設定' : title}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            'スコア: ${score}点\n日付: ${DateFormat('yyyy/MM/dd HH:mm').format(date)}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  fav ? Icons.star : Icons.star_border,
                                  color: fav ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () => _toggleFavorite(index),
                                tooltip: fav ? 'お気に入り解除' : 'お気に入り',
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.black87),
                                onPressed: () => _playRecording(path),
                                tooltip: '再生',
                              ),
                              // ←「採点を見る」ボタンを足すならここに
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
