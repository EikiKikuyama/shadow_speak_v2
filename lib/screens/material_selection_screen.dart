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
      appBar: AppBar(title: const Text('題材を選択')),
      body: ListView.builder(
        itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          return ListTile(
              title: Text(material.title),
              leading: const Icon(Icons.audiotrack),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                ref.read(selectedMaterialProvider.notifier).state = material;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PracticeModeSelectionScreen(),
                  ),
                );
              });
        },
      ),
    );
  }
}
