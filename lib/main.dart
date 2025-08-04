import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import 'package:shadow_speak_v2/settings/settings_controller.dart';
import 'package:shadow_speak_v2/screens/splash_screen.dart';
import 'package:shadow_speak_v2/screens/main_screen.dart'; // ← MainScreen を使う！
import 'package:shadow_speak_v2/screens/recording_history_screen.dart';
import 'package:shadow_speak_v2/screens/progress_screen.dart';
import '../gen_l10n/app_localizations.dart';
import 'package:shadow_speak_v2/settings/font_size/font_size_option.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(); // ✅ 環境変数の読み込み
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ APIキーが読み込めていません');
    } else {
      print('✅ APIキーの読み込みに成功しました');
    }
  } catch (e) {
    print('❌ dotenv 読み込み失敗: $e');
  }

  // ✅ assetの確認コード（お好みで削除可）
  final subtitlePath =
      'assets/subtitles/Level1/Announcement/Simple_Station_Announcement.json';
  final audioPath =
      'assets/audio/Level1/Announcement/Simple_Station_Announcement.wav';

  try {
    await rootBundle.loadString(subtitlePath);
    print('✅ JSON asset読み込み成功: $subtitlePath');
  } catch (error) {
    print('❌ JSON asset読み込み失敗: $subtitlePath → $error');
  }

  try {
    await rootBundle.load(audioPath);
    print('✅ WAV asset読み込み成功: $audioPath');
  } catch (error) {
    print('❌ WAV asset読み込み失敗: $audioPath → $error');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.watch(settingsControllerProvider);
    final scaleFactor = settingsController.fontSize.scaleFactor;

    return MaterialApp(
      // --- ローカライズ ---
      locale: settingsController.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // --- その他 ---
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: scaleFactor),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(), // ✅ ここが MainScreen に！
        '/history': (context) => const RecordingHistoryScreen(),
        '/progress': (context) => const ProgressScreen(),
      },
    );
  }
}
