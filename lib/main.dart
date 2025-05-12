import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/material_selection_screen.dart'; // ← 必要に応じて変更

void main() {
  runApp(
    const ProviderScope(
      // ← これでアプリ全体を囲む
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MaterialSelectionScreen(),
    );
  }
}
