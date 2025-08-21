import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadow_speak_v2/gen_l10n/app_localizations.dart';
import 'package:shadow_speak_v2/screens/material_selection_screen.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';

class LevelHomeScreen extends ConsumerWidget {
  final void Function(String level)? onLevelSelected; // ← 追加

  const LevelHomeScreen({super.key, this.onLevelSelected}); // ← コンストラクタに追加

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;
    final t = AppLocalizations.of(context)!;

    return isDarkMode ? _buildDarkUI(context, t) : _buildLightUI(context, t);
  }

  Widget _buildLightUI(BuildContext context, AppLocalizations t) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: t.levelSelectTitle,
        backgroundColor: const Color(0xFFF3F0FA),
        titleColor: Colors.black,
        iconColor: Colors.black,
        actions: [],
      ),
      body: _buildLevelList(context, t, isDarkMode: false),
    );
  }

  Widget _buildDarkUI(BuildContext context, AppLocalizations t) {
    return Scaffold(
      backgroundColor: const Color(0xFF001042),
      appBar: CustomAppBar(
        title: t.levelSelectTitle,
        backgroundColor: const Color(0xFF0C1A3E),
        titleColor: Colors.white,
        iconColor: Colors.white,
        actions: [],
      ),
      body: _buildLevelList(context, t, isDarkMode: true),
    );
  }

  Widget _buildLevelList(BuildContext context, AppLocalizations t,
      {required bool isDarkMode}) {
    final levels = [
      {
        'key': 'Starter',
        'title': t.levelStarterTitle,
        'description': t.levelStarterDesc,
        'color': Colors.green,
      },
      {
        'key': 'Basic',
        'title': t.levelBasicTitle,
        'description': t.levelBasicDesc,
        'color': Colors.blue,
      },
      {
        'key': 'Intermediate',
        'title': t.levelIntermediateTitle,
        'description': t.levelIntermediateDesc,
        'color': Colors.amber,
      },
      {
        'key': 'Upper',
        'title': t.levelUpperTitle,
        'description': t.levelUpperDesc,
        'color': Colors.orange,
      },
      {
        'key': 'Advanced',
        'title': t.levelAdvancedTitle,
        'description': t.levelAdvancedDesc,
        'color': Colors.red,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: levels.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return RecommendedLevelCard(
            levelTitle: t.levelBasicTitle,
            reasonText: "最近の練習傾向から「Basic」が最適です。",
            isDarkMode: isDarkMode,
          );
        }

        final level = levels[index - 1];

        return GestureDetector(
          onTap: () {
            final fullTitle = level['title'] as String;
            debugPrint('🚀 選択されたレベル: $fullTitle');

            if (onLevelSelected != null) {
              onLevelSelected!(fullTitle);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaterialSelectionScreen(level: fullTitle),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isDarkMode
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color(0xFFEDE7F6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: level['color'] as Color,
                radius: 10,
              ),
              title: Text(
                level['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDarkMode
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                level['description'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color.fromARGB(179, 0, 0, 0)
                      : Colors.black87,
                ),
              ),
              trailing: Icon(Icons.chevron_right,
                  color: isDarkMode ? Colors.white : Colors.black54),
            ),
          ),
        );
      },
    );
  }
}

class RecommendedLevelCard extends StatelessWidget {
  final String levelTitle;
  final String reasonText;
  final bool isDarkMode;

  const RecommendedLevelCard({
    super.key,
    required this.levelTitle,
    required this.reasonText,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color:
          isDarkMode ? Colors.deepPurple.shade700 : Colors.deepPurple.shade100,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.recommend,
            size: 32, color: isDarkMode ? Colors.white : Colors.deepPurple),
        title: Text(
          "あなたにおすすめのレベル",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          reasonText,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
