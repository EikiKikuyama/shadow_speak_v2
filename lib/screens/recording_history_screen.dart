import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart'; // ✅ ダークモード判定用

class RecordingHistoryScreen extends ConsumerStatefulWidget {
  const RecordingHistoryScreen({super.key});

  @override
  ConsumerState<RecordingHistoryScreen> createState() =>
      _RecordingHistoryScreenState();
}

class _RecordingHistoryScreenState
    extends ConsumerState<RecordingHistoryScreen> {
  List<Map<String, dynamic>> recordings = [];
  Set<String> favoritePaths = {};
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadFavorites().then((_) => _loadRecordings());
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoritePaths = prefs.getStringList('favorites')?.toSet() ?? {};
    setState(() {});
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favoritePaths.toList());
  }

  Future<void> _loadRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/shadow_speak/recordings');

    if (!await folder.exists()) return;

    final files = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .toList();

    final loadedRecordings = files.map((file) {
      final stat = file.statSync();
      final filename = file.uri.pathSegments.last.replaceAll('.wav', '');

      String level = '未設定';
      String title = '未設定';

      final parts = filename.split('__');
      if (parts.length >= 3) {
        level = _convertLevel(parts[0]);
        title = parts[1].replaceAll('-', ' ').trim();
      }

      return {
        'title': title,
        'level': level,
        'path': file.path,
        'score': Random().nextInt(35) + 60,
        'date': stat.modified,
        'isFavorite': favoritePaths.contains(file.path),
      };
    }).toList();

    loadedRecordings.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    setState(() {
      recordings = loadedRecordings.take(10).toList();
    });
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

  void _toggleFavorite(int index) async {
    final path = recordings[index]['path'];
    setState(() {
      recordings[index]['isFavorite'] = !recordings[index]['isFavorite'];
      if (recordings[index]['isFavorite']) {
        favoritePaths.add(path);
      } else {
        favoritePaths.remove(path);
      }
    });
    await _saveFavorites();
  }

  Future<void> _deleteRecording(int index) async {
    final path = recordings[index]['path'];

    await player.stop();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    favoritePaths.remove(path);
    await _saveFavorites();

    setState(() {
      recordings.removeAt(index);
    });
  }

  Future<void> _playRecording(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルが見つかりません')),
      );
      return;
    }

    await player.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await player.play(DeviceFileSource(path));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

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
      ),
      body: recordings.isEmpty
          ? const Center(
              child: Text('録音が見つかりません。', style: TextStyle(color: Colors.white)))
          : ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final item = recordings[index];
                return Dismissible(
                  key: ValueKey(item['path']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteRecording(index),
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        'レベル: ${item['level']} / 教材: ${item['title']}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Text(
                        'スコア: ${item['score']}点\n日付: ${DateFormat('yyyy/MM/dd HH:mm').format(item['date'])}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              item['isFavorite']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: item['isFavorite']
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow,
                                color: Colors.black87),
                            onPressed: () => _playRecording(item['path']),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
