import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/practice_mode_provider.dart';
import '../providers/selected_material_provider.dart';
import '../screens/practice_screen.dart';
import '../models/material_model.dart';
import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart'; // ✅ 追加

class PracticeModeSelectionScreen extends ConsumerWidget {
  final PracticeMaterial material;

  const PracticeModeSelectionScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;

    final backgroundColor =
        isDarkMode ? const Color(0xFF001042) : const Color(0xFFF3F0FA);
    final appBarColor =
        isDarkMode ? const Color(0xFF0C1A3E) : const Color(0xFFF3F0FA);
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: "モードを選んでください",
        backgroundColor: appBarColor,
        titleColor: titleColor,
        iconColor: iconColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildModeCard(
              title: 'Auto Mode',
              description: '全モードを自動で順番に練習できるモード',
              icon: Icons.autorenew,
              onTap: () => _navigate(context, ref, PracticeMode.listening),
            ),
            _buildModeCard(
              title: 'Listening',
              description: '音声を聞き取り、内容を理解することに集中するモード',
              icon: Icons.headphones,
              onTap: () => _navigate(context, ref, PracticeMode.listening),
            ),
            _buildModeCard(
              title: 'Overlapping',
              description: '字幕を見ながら、聞こえた音声にぴったり合わせて同時に発音するモード',
              icon: Icons.surround_sound,
              onTap: () => _navigate(context, ref, PracticeMode.overlapping),
            ),
            _buildModeCard(
              title: 'Shadowing',
              description: '聞こえた音声のすぐあとに続いて、真似して発音する練習モード',
              icon: Icons.repeat,
              onTap: () => _navigate(context, ref, PracticeMode.shadowing),
            ),
            _buildModeCard(
              title: 'Recording Only',
              description: '音声を聞かず、自分の発音だけを録音するモード',
              icon: Icons.mic,
              onTap: () => _navigate(context, ref, PracticeMode.recordingOnly),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? const Color(0xFF0C1A3E) : Colors.white,
        currentIndex: 0,
        selectedItemColor: isDarkMode ? Colors.white : Colors.deepPurple,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey,
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

  void _navigate(BuildContext context, WidgetRef ref, PracticeMode mode) {
    ref.read(practiceModeProvider.notifier).state = mode;
    ref.read(selectedMaterialProvider.notifier).state = material;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PracticeScreen()),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white, // ✅ ダークでも白固定
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color.fromARGB(255, 20, 19, 19)),
            ],
          ),
        ),
      ),
    );
  }
}
