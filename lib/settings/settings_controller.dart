import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_size/font_size_option.dart';
import 'locale/locale_option.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsController with ChangeNotifier {
  // === 現在の設定状態 ===
  FontSizeOption _fontSize = FontSizeOption.medium;
  LocaleOption _localeOption = LocaleOption.system;
  ThemeMode _themeMode = ThemeMode.system;

  // === Getter ===
  FontSizeOption get fontSize => _fontSize;
  LocaleOption get localeOption => _localeOption;
  ThemeMode get themeMode => _themeMode;
  Locale? get currentLocale => _localeOption.toLocale;

  // === 初期設定の読み込み ===
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = FontSizeOption.values[prefs.getInt('fontSize') ?? 1];
    _localeOption = LocaleOption.values[prefs.getInt('locale') ?? 0];
    _themeMode = _stringToThemeMode(prefs.getString('themeMode') ?? 'system');
  }

  // === 設定の更新 ===
  Future<void> setFontSize(FontSizeOption newSize) async {
    _fontSize = newSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', _fontSize.index);
    notifyListeners();
  }

  Future<void> setLocaleOption(LocaleOption option) async {
    _localeOption = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('locale', option.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    _themeMode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(newMode));
    notifyListeners();
  }

  // === 内部ユーティリティ ===
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}

// === Riverpodプロバイダ ===
final settingsControllerProvider =
    ChangeNotifierProvider<SettingsController>((ref) {
  final controller = SettingsController();
  controller.loadSettings(); // Future だが Fire-and-forget
  return controller;
});
