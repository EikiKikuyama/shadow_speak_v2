import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../data/practice_materials.dart';
import '../../screens/practice_mode_selection_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final recommended = filteredMaterials.take(2).toList();
    final others = filteredMaterials.skip(2).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.level} の教材",
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
