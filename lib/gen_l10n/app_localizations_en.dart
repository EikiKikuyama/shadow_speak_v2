// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shadow Speak';

  @override
  String get settings => 'Settings';

  @override
  String get fontSize => 'Font Size';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get selectLevel => 'Select Level';

  @override
  String get levelStarterTitle => 'Starter (〜50 words)';

  @override
  String get levelStarterDesc =>
      'Short sentences, beginner words (Junior high level)';

  @override
  String get levelBasicTitle => 'Basic (〜80 words)';

  @override
  String get levelBasicDesc => 'Everyday expressions, basic vocabulary';

  @override
  String get levelIntermediateTitle => 'Intermediate (〜100 words)';

  @override
  String get levelIntermediateDesc =>
      'Great for conversation and speech training';

  @override
  String get levelUpperTitle => 'Upper (〜130 words)';

  @override
  String get levelUpperDesc => 'Challenging sentence structures';

  @override
  String get levelAdvancedTitle => 'Advanced (〜150 words)';

  @override
  String get levelAdvancedDesc => 'Full-scale English practice (over 1 minute)';

  @override
  String get levelSelectTitle => 'Select your level';
}
