import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_size/font_size_option.dart';
import 'locale/locale_option.dart';

class SettingsController with ChangeNotifier {
  // === 現在の設定状態 ===
  FontSizeOption _fontSize = FontSizeOption.medium;
  LocaleOption _localeOption = LocaleOption.system;
  bool _isDarkMode = false;

  // === Getter ===
  FontSizeOption get fontSize => _fontSize;
  LocaleOption get localeOption => _localeOption;
  bool get isDarkMode => _isDarkMode;
  Locale? get currentLocale => _localeOption.toLocale;

  // === 初期設定の読み込み ===
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = FontSizeOption.values[prefs.getInt('fontSize') ?? 1];
    _localeOption = LocaleOption.values[prefs.getInt('locale') ?? 0];
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
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

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
}

// === Riverpod プロバイダ ===
final settingsControllerProvider =
    ChangeNotifierProvider<SettingsController>((ref) {
  final controller = SettingsController();
  controller.loadSettings(); // 初期設定を読み込む（非同期だけど fire-and-forget）
  return controller;
});
