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
  String get levelStarterDesc => '超初級。短くてわかりやすい文章で発音練習を始めたい方に。';

  @override
  String get levelBasicTitle => 'Basic（〜80語）';

  @override
  String get levelBasicDesc => '基礎力をつけたい方へ。中学英語レベルの会話文で耳と口を慣らします。';

  @override
  String get levelIntermediateTitle => 'Intermediate（〜100語）';

  @override
  String get levelIntermediateDesc => '少し長めの英文に挑戦。スピーチ練習にもぴったりのレベルです。';

  @override
  String get levelUpperTitle => 'Upper（〜130語）';

  @override
  String get levelUpperDesc => '接続詞や複雑な構文が登場。聞く・話すの力をさらに伸ばします。';

  @override
  String get levelAdvancedTitle => 'Advanced（〜150語）';

  @override
  String get levelAdvancedDesc => '本物の英語スピーチに挑戦。1分以上の実践的な素材を収録。';

  @override
  String get levelSelectTitle => 'レベルを選んでください';
}
