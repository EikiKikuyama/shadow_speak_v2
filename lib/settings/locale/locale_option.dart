import 'package:flutter/material.dart'; // ← これで Locale が使えるようになる

enum LocaleOption { system, english, japanese }

extension LocaleOptionExtension on LocaleOption {
  String get displayName {
    switch (this) {
      case LocaleOption.system:
        return 'システム設定';
      case LocaleOption.english:
        return 'English';
      case LocaleOption.japanese:
        return '日本語';
    }
  }

  Locale? get toLocale {
    switch (this) {
      case LocaleOption.system:
        return null;
      case LocaleOption.english:
        return const Locale('en');
      case LocaleOption.japanese:
        return const Locale('ja');
    }
  }

  static LocaleOption fromLocale(Locale? locale) {
    if (locale == null) return LocaleOption.system;
    switch (locale.languageCode) {
      case 'en':
        return LocaleOption.english;
      case 'ja':
        return LocaleOption.japanese;
      default:
        return LocaleOption.system;
    }
  }
}
