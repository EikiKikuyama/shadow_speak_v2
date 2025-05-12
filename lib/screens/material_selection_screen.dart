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
      audioPath: 'assets/audio/announcement.wav',
      scriptPath: 'assets/scripts/announcement.txt',
    ),
    PracticeMaterial(
      id: 'Mt.Fuji',
      title: 'Mount Fuji Intro',
      audioPath: 'assets/audio/Mt.Fuji.wav',
      scriptPath: 'assets/scripts/Mt.Fuji.txt',
    ),
    PracticeMaterial(
      id: 'WeatherForecast',
      title: 'Weather Forecast',
      audioPath: 'assets/audio/Weatherannounce.wav',
      scriptPath: 'assets/scripts/Weatherannounce.txt',
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
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const PracticeModeSelectionScreen(),
    ),
  );
}

          );
        },
      ),
    );
  }
}
