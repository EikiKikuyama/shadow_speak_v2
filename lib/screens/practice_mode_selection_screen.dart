import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../providers/selected_material_provider.dart';
import '../screens/practice_screen.dart';
import '../data/practice_materials.dart';
import '../models/material_model.dart';
import '../widgets/custom_app_bar.dart';

class PracticeModeSelectionScreen extends ConsumerWidget {
  final PracticeMaterial material;

  const PracticeModeSelectionScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      appBar: const CustomAppBar(
        title: "モードを選んでください",
        backgroundColor: Color(0xFFF3F0FA),
        titleColor: Colors.black87,
        iconColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildModeCard(
              title: 'Auto Mode',
              description: '全モードを自動で順に練習できます',
              icon: Icons.autorenew,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.listening;
                ref.read(selectedMaterialProvider.notifier).state = material;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
            _buildModeCard(
              title: 'Listening',
              description: '聞き取りに集中するモードです',
              icon: Icons.headphones,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.listening;
                ref.read(selectedMaterialProvider.notifier).state = material;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
            _buildModeCard(
              title: 'Overlapping',
              description: '同時に音声を重ねて発音します',
              icon: Icons.surround_sound,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.overlapping;
                ref.read(selectedMaterialProvider.notifier).state = material;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
            _buildModeCard(
              title: 'Shadowing',
              description: '一拍遅れてマネする発音練習です',
              icon: Icons.repeat,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.shadowing;
                ref.read(selectedMaterialProvider.notifier).state = material;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
            _buildModeCard(
              title: 'Recording Only',
              description: '録音だけを行うシンプルなモード',
              icon: Icons.mic,
              onTap: () {
                ref.read(practiceModeProvider.notifier).state =
                    PracticeMode.recordingOnly;
                ref.read(selectedMaterialProvider.notifier).state = material;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/history');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/progress');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '進捗'),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
