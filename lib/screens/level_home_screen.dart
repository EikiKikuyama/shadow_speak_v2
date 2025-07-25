import 'package:flutter/material.dart';
import 'package:shadow_speak_v2/gen_l10n/app_localizations.dart';
import 'material_selection_screen.dart';
import 'package:shadow_speak_v2/widgets/custom_app_bar.dart';

class LevelHomeScreen extends StatelessWidget {
  const LevelHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final levels = [
      {
        'title': t.levelStarterTitle,
        'description': t.levelStarterDesc,
        'color': Colors.green,
      },
      {
        'title': t.levelBasicTitle,
        'description': t.levelBasicDesc,
        'color': Colors.blue,
      },
      {
        'title': t.levelIntermediateTitle,
        'description': t.levelIntermediateDesc,
        'color': Colors.amber,
      },
      {
        'title': t.levelUpperTitle,
        'description': t.levelUpperDesc,
        'color': Colors.orange,
      },
      {
        'title': t.levelAdvancedTitle,
        'description': t.levelAdvancedDesc,
        'color': Colors.red,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: t.levelSelectTitle),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          return GestureDetector(
            onTap: () {
              final fullTitle = level['title'] as String;
              final parsedLevel = fullTitle.split('（').first;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaterialSelectionScreen(level: parsedLevel),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: const Color(0xFFEDE7F6),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  level['description'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        },
      ),
    );
  }
}
