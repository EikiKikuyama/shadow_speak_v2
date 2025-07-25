import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../data/practice_materials.dart';
import '../../screens/practice_mode_selection_screen.dart';
import '../../widgets/custom_app_bar.dart';

class MaterialSelectionScreen extends StatefulWidget {
  final String level;

  const MaterialSelectionScreen({super.key, required this.level});

  @override
  State<MaterialSelectionScreen> createState() =>
      _MaterialSelectionScreenState();
}

class _MaterialSelectionScreenState extends State<MaterialSelectionScreen> {
  String selectedCategory = 'すべて';
  String searchQuery = '';

  List<String> categories = ['すべて', '日常会話', 'ビジネス', '旅行', '放送'];

  List<PracticeMaterial> get filteredMaterials {
    return allMaterials.where((material) {
      final matchesLevel = material.level == widget.level;
      final matchesCategory =
          selectedCategory == 'すべて' || material.tag == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty || material.title.contains(searchQuery);
      return matchesLevel && matchesCategory && matchesSearch;
    }).toList();
  }

  int _currentIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/history');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/progress');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommended = filteredMaterials.take(2).toList();
    final others = filteredMaterials.skip(2).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "${widget.level} の教材",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 12),
            _buildSearchField(),
            const SizedBox(height: 20),
            if (recommended.isNotEmpty) _buildSectionTitle('おすすめ教材'),
            if (recommended.isNotEmpty) ...recommended.map(_buildMaterialItem),
            const SizedBox(height: 16),
            _buildSectionTitle('教材一覧'),
            Expanded(
              child: ListView.builder(
                itemCount: others.length,
                itemBuilder: (context, index) {
                  return _buildMaterialItem(others[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '進捗'),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() => selectedCategory = category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'タイトルまたはキーワードで検索',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) => setState(() => searchQuery = value),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMaterialItem(PracticeMaterial material) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PracticeModeSelectionScreen(material: material),
            ),
          );
        },
        title: Text(material.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${material.durationSec}秒・${material.wordCount}語'),
      ),
    );
  }
}
