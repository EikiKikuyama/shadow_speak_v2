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
    final isDarkMode = settingsController.isDarkMode;

    final backgroundColor = isDarkMode ? const Color(0xFF102542) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final appBarColor = isDarkMode ? const Color(0xFF0C1A3E) : Colors.white;
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text('設定', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: iconColor),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('フォントサイズ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              SegmentedButton<FontSizeOption>(
                segments: FontSizeOption.values.map((option) {
                  return ButtonSegment<FontSizeOption>(
                    value: option,
                    label: Text(option.displayName,
                        style: TextStyle(color: textColor)),
                  );
                }).toList(),
                selected: {settingsController.fontSize},
                onSelectionChanged: (Set<FontSizeOption> newSelection) {
                  if (newSelection.isNotEmpty) {
                    settingsController.setFontSize(newSelection.first);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text('言語',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              DropdownButton<LocaleOption>(
                dropdownColor: backgroundColor,
                value: settingsController.localeOption,
                iconEnabledColor: textColor,
                style: TextStyle(color: textColor),
                items: LocaleOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option.displayName,
                        style: TextStyle(color: textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setLocaleOption(value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text('テーマ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              SwitchListTile(
                title:
                    Text('ライトモードorダークモード', style: TextStyle(color: textColor)),
                value: settingsController.isDarkMode,
                onChanged: (value) {
                  ref.read(settingsControllerProvider).setDarkMode(value);
                },
                activeColor: Colors.deepPurple,
                inactiveThumbColor: Colors.grey,
                tileColor: backgroundColor,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
