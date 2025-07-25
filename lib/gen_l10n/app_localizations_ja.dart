// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'シャドースピーク';

  @override
  String get settings => '設定';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get selectLevel => 'レベル選択';

  @override
  String get levelStarterTitle => 'Starter（〜50語）';

  @override
  String get levelStarterDesc => '短い文章・簡単な語彙・中1レベル単語';

  @override
  String get levelBasicTitle => 'Basic（〜80語）';

  @override
  String get levelBasicDesc => '基本的な日常表現・中学生英語レベル';

  @override
  String get levelIntermediateTitle => 'Intermediate（〜100語）';

  @override
  String get levelIntermediateDesc => '会話・スピーチの練習に最適';

  @override
  String get levelUpperTitle => 'Upper（〜130語）';

  @override
  String get levelUpperDesc => '複雑な文構造にも挑戦できるレベル';

  @override
  String get levelAdvancedTitle => 'Advanced（〜150語）';

  @override
  String get levelAdvancedDesc => '本格的な英語力が試されるレベル（1分超）';

  @override
  String get levelSelectTitle => 'レベルを選んでください';
}
