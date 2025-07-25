import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadow_speak_v2/settings/settings_controller.dart';
import 'package:shadow_speak_v2/settings/font_size/font_size_option.dart';
import 'package:shadow_speak_v2/settings/locale/locale_option.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('フォントサイズ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<FontSizeOption>(
              value: settingsController.fontSize,
              items: FontSizeOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  settingsController.setFontSize(value);
                }
              },
            ),
            const SizedBox(height: 24),
            const Text('言語',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<LocaleOption>(
              value: settingsController.localeOption,
              items: LocaleOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  settingsController.setLocaleOption(value);
                }
              },
            ),
            const SizedBox(height: 24),
            const Text('テーマ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<ThemeMode>(
              value: settingsController.themeMode,
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('システムに従う')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text('ライトモード（白紫）')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text('ダークモード（濃紺）')),
              ],
              onChanged: (value) {
                if (value != null) {
                  settingsController.setThemeMode(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
