import 'package:flutter/material.dart';
import 'material_selection_screen.dart'; // ファイル名に応じて修正

class LevelHomeScreen extends StatelessWidget {
  const LevelHomeScreen({super.key});

  final List<Map<String, dynamic>> levels = const [
    {
      'title': 'Starter（〜50語）',
      'description': '短い文章・簡単な語彙・中1レベル単語',
      'color': Colors.green,
    },
    {
      'title': 'Basic（〜80語）',
      'description': '基本的な日常表現・中学生英語レベル',
      'color': Colors.blue,
    },
    {
      'title': 'Intermediate（〜100語）',
      'description': '会話・スピーチの練習に最適',
      'color': Colors.amber,
    },
    {
      'title': 'Upper（〜130語）',
      'description': '複雑な文構造にも挑戦できるレベル',
      'color': Colors.orange,
    },
    {
      'title': 'Advanced（〜150語）',
      'description': '本格的な英語力が試されるレベル（1分超）',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ← 背景を白に変更
      appBar: AppBar(
        title: const Text('レベル選択', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, // ← AppBarも白に
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          return GestureDetector(
            onTap: () {
              final fullTitle = level['title'] as String;
              final parsedLevel = fullTitle.split('（').first;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MaterialSelectionScreen(level: parsedLevel), // 修正済
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: const Color(0xFFEDE7F6), // ← ラベンダー系カラーに変更
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: level['color'],
                  radius: 10,
                ),
                title: Text(
                  level['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  level['description'],
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple, // ラベンダーに合う濃紫
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // TODO: 履歴や進捗に切り替え
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '進捗'),
        ],
      ),
    );
  }
}
