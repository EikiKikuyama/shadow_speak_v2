import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart'; // ← これが rootBundle の正体

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

  // ✅ assetの確認コードをここに追加！
  final assetPath = 'assets/audio/announcement.wav';

  try {
    await rootBundle.load(assetPath);
    print('✅ asset読み込み成功: $assetPath');
  } catch (error) {
    print('❌ asset読み込み失敗: $assetPath → $error');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ← これが必須！
      home: SplashScreen(),
    );
  }
}
