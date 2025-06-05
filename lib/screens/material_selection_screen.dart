import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_model.dart';
import '../providers/selected_material_provider.dart';
import 'practice_mode_selection_screen.dart';

class MaterialSelectionScreen extends ConsumerWidget {
  final List<PracticeMaterial> materials = [
    PracticeMaterial(
      id: 'TrainAnnouncement',
      title: 'Train Announcement',
      audioPath: 'audio/announcement.wav',
      scriptPath: 'assets/scripts/announcement.txt',
    ),
    PracticeMaterial(
      id: 'Mt.Fuji',
      title: 'Mount Fuji Intro',
      audioPath: 'audio/Mt.Fuji.wav',
      scriptPath: 'assets/scripts/Mt.Fuji.txt',
    ),
    PracticeMaterial(
      id: 'WeatherForecast',
      title: 'Weather Forecast',
      audioPath: 'audio/Weatherannounce.wav',
      scriptPath: 'assets/scripts/Weatherannounce.txt',
    ),
    PracticeMaterial(
      id: 'introduction',
      title: 'Introduction',
      audioPath: 'audio/introduction.wav',
      scriptPath: 'assets/scripts/introduction.txt',
    ),
    PracticeMaterial(
      id: 'School Announcement',
      title: 'School Announcement',
      audioPath: 'audio/school_announcement.wav',
      scriptPath: 'assets/scripts/school_announcement.txt',
    ),
    PracticeMaterial(
      id: 'Weather',
      title: 'Weather',
      audioPath: 'audio/weather.wav',
      scriptPath: 'assets/scripts/weather.txt',
    ),
  ];

  MaterialSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32), // 黒板グリーン背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '題材を選択',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return _buildMaterialTile(material, ref, context);
          },
        ),
      ),
    );
  }

  Widget _buildMaterialTile(
      PracticeMaterial material, WidgetRef ref, BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5E9), // 明るい緑（ノート風）
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const Icon(Icons.audiotrack, color: Colors.green),
        title: Text(
          material.title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          ref.read(selectedMaterialProvider.notifier).state = material;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PracticeModeSelectionScreen(),
            ),
          );
        },
      ),
    );
  }
}
