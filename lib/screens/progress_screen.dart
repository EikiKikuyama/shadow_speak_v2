import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/custom_app_bar.dart';
import '../settings/settings_controller.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Set<DateTime> practicedDays = {};
  int totalDays = 0;
  int streak = 0;
  int thisMonthUniqueDays = 0;
  int thisMonthRecordingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPracticeDays();
  }

  Future<void> _loadPracticeDays() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/shadow_speak/recordings');

    if (!await folder.exists()) return;

    final files = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .toList();

    final Set<DateTime> uniqueDays = {};
    final today = DateTime.now();

    for (final file in files) {
      final modified = file.statSync().modified;
      uniqueDays.add(DateTime(modified.year, modified.month, modified.day));
    }

    int currentStreak = 0;
    DateTime day = DateTime(today.year, today.month, today.day);
    while (uniqueDays.contains(day)) {
      currentStreak++;
      day = day.subtract(const Duration(days: 1));
    }

    int thisMonthCount = uniqueDays
        .where((d) => d.year == today.year && d.month == today.month)
        .length;

    int thisMonthFiles = files.where((file) {
      final m = file.statSync().modified;
      return m.year == today.year && m.month == today.month;
    }).length;

    setState(() {
      practicedDays = uniqueDays;
      totalDays = uniqueDays.length;
      streak = currentStreak;
      thisMonthUniqueDays = thisMonthCount;
      thisMonthRecordingCount = thisMonthFiles;
    });
  }

  bool _isPracticedDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return practicedDays.contains(normalized);
  }

  String get advice {
    if (streak >= 10) {
      return '素晴らしい継続力です！この調子！';
    } else if (streak >= 5) {
      return 'いい感じ！あと${10 - streak}日で10日連続達成！';
    } else if (streak >= 1) {
      return '連続練習を習慣にしていこう！';
    } else {
      return 'まずは1日、始めてみよう！';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsControllerProvider).isDarkMode;
    final weekendColor = isDarkMode ? Colors.grey[300]! : Colors.grey;
    final backgroundColor =
        isDarkMode ? const Color(0xFF102542) : const Color(0xFFF8F3FA);
    final cardColor = Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87; // ←ここ！
    final appBarColor = isDarkMode ? const Color(0xFF0C1A3E) : Colors.white;
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: '進歩',
        backgroundColor: appBarColor,
        titleColor: iconColor,
        iconColor: iconColor,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: textColor, fontSize: 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: weekendColor),
              weekdayStyle: TextStyle(color: textColor),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Color(0xFFD1C4E9),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: textColor),
              weekendTextStyle: TextStyle(color: weekendColor),
              markerDecoration: const BoxDecoration(color: Colors.transparent),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (_isPracticedDay(date)) {
                  return Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepPurple, width: 2),
                      ),
                      child: const Center(
                        child: Text('◉',
                            style: TextStyle(
                                color: Colors.deepPurple, fontSize: 12)),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('🔥', '練習継続日数', '$streak 日', textColor),
                _buildInfoRow('📊', '練習した日数', '$totalDays 日', textColor),
                _buildInfoRow(
                    '🗓', '今月の練習日数', '$thisMonthUniqueDays 日', textColor),
                _buildInfoRow(
                    '🎙', '今月の録音回数', '$thisMonthRecordingCount 回', textColor),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cardColor,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'アドバイス: $advice',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black, // ← ここだけ黒に固定！
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20, color: textColor)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(value, style: TextStyle(fontSize: 16, color: textColor)),
        ],
      ),
    );
  }
}
