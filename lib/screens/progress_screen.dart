import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/custom_app_bar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: const CustomAppBar(
        title: '進歩',
        backgroundColor: Colors.white,
        titleColor: Colors.black,
        iconColor: Colors.black,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.grey),
              weekdayStyle: TextStyle(color: Colors.black87),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFD1C4E9),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: Colors.grey),
              markerDecoration: BoxDecoration(color: Colors.transparent),
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
                _buildInfoRow('🔥', '練習継続日数', '$streak 日'),
                _buildInfoRow('📊', '練習した日数', '$totalDays 日'),
                _buildInfoRow('🗓', '今月の練習日数', '$thisMonthUniqueDays 日'),
                _buildInfoRow('🎙', '今月の録音回数', '$thisMonthRecordingCount 回'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'アドバイス: $advice',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
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

  Widget _buildInfoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
