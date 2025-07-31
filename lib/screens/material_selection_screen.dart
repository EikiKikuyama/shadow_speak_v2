import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadow_speak_v2/models/material_model.dart';
import 'package:shadow_speak_v2/data/practice_materials.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';
import 'package:shadow_speak_v2/screens/settings_screen.dart';
import 'package:shadow_speak_v2/screens/practice_mode_selection_screen.dart';

class MaterialSelectionScreen extends ConsumerStatefulWidget {
  final String level;

  const MaterialSelectionScreen({super.key, required this.level});

  @override
  ConsumerState<MaterialSelectionScreen> createState() =>
      _MaterialSelectionScreenState();
}

class _MaterialSelectionScreenState
    extends ConsumerState<MaterialSelectionScreen> {
  String selectedCategory = 'すべて';
  String searchQuery = '';

  List<String> get uniqueTags {
    final tags = allMaterials.map((m) => m.tag).toSet().toList();
    tags.sort();
    return ['すべて', ...tags];
  }

  String get mappedLevel {
    final level = widget.level;
    if (level.contains('スターター') || level.contains('Starter')) return 'Starter';
    if (level.contains('ベーシック') || level.contains('Basic')) return 'Basic';
    if (level.contains('中級') || level.contains('Intermediate'))
      return 'Intermediate';
    if (level.contains('上級') && !level.contains('最')) return 'Upper';
    if (level.contains('最上級') || level.contains('Advanced')) return 'Advanced';
    final trimmed = level.split('（').first.trim();
    return trimmed;
  }

  List<PracticeMaterial> get filteredMaterials {
    return allMaterials.where((material) {
      final matchesLevel =
          material.level.trim().toLowerCase() == mappedLevel.toLowerCase();
      final matchesCategory =
          selectedCategory == 'すべて' || material.tag == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          material.title.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesLevel && matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;

    final backgroundColor = isDarkMode ? const Color(0xFF001042) : Colors.white;
    final cardColor = isDarkMode ? Colors.white : const Color(0xFFF3F0FA);
    final textColor = isDarkMode ? Colors.black : Colors.black87;
    final borderColor = isDarkMode ? Colors.white24 : Colors.grey[300];
    final hintTextColor = isDarkMode ? Colors.white54 : Colors.grey;
    final appBarBgColor =
        isDarkMode ? const Color(0xFF0C1A3E) : const Color(0xFFF3F0FA);
    final appBarTextColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.level} の教材',
          style: TextStyle(color: appBarTextColor), // タイトル文字色
        ),
        backgroundColor: appBarBgColor,
        iconTheme: IconThemeData(color: iconColor), // ← ← 戻るボタン色
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: iconColor), // ← ← 設定ボタン色
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'タイトル検索',
                hintStyle: TextStyle(color: hintTextColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor!),
                ),
                prefixIcon: Icon(Icons.search, color: hintTextColor),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: uniqueTags.map((tag) {
                  final isSelected = selectedCategory == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        selectedCategory = tag;
                      }),
                      selectedColor:
                          isDarkMode ? Colors.blueGrey : Colors.deepPurple[100],
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode ? Colors.white70 : Colors.black),
                      ),
                      backgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredMaterials.isEmpty
                  ? Center(
                      child: Text(
                        '該当する教材がありません',
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMaterials.length,
                      itemBuilder: (context, index) {
                        final material = filteredMaterials[index];
                        return Card(
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              material.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              '${material.wordCount}語 / 約${material.durationSec}秒',
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: textColor.withOpacity(0.7),
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PracticeModeSelectionScreen(
                                      material: material),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/history');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/progress');
          }
        },
        backgroundColor: isDarkMode ? const Color(0xFF0C1A3E) : Colors.white,
        selectedItemColor: isDarkMode ? Colors.white : Colors.deepPurple,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '進捗'),
        ],
      ),
    );
  }
}
