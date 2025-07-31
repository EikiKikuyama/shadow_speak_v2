// lib/data/practice_materials.dart

import '../models/material_model.dart';

// 日本語表示レベル → 英語レベルへ変換
String mapLevelToEnglish(String level) {
  switch (level) {
    case 'スターター':
    case 'スターター（〜50語）':
      return 'Starter';
    case 'ベーシック':
    case 'ベーシック（〜100語）':
      return 'Basic';
    case '中級':
    case '中級（〜150語）':
      return 'Intermediate';
    case '上級':
    case '上級（〜200語）':
      return 'Upper';
    case '最上級':
    case '最上級（〜300語）':
      return 'Advanced';
    default:
      return level;
  }
}

List<PracticeMaterial> allMaterials = [
  PracticeMaterial(
    id: 'TrainAnnouncement',
    title: 'Train Announcement',
    audioPath: 'audio/announcement.wav',
    scriptPath: 'assets/subtitles/announcement.json',
    level: 'Starter',
    tag: 'Travel',
    durationSec: 5,
    wordCount: 45,
  ),
  PracticeMaterial(
    id: 'Mt.Fuji',
    title: 'Mount Fuji Intro',
    audioPath: 'audio/Mt.Fuji.wav',
    scriptPath: 'assets/subtitles/Mt.Fuji.json',
    level: 'Basic',
    tag: 'Intro',
    durationSec: 7,
    wordCount: 72,
  ),
  PracticeMaterial(
    id: 'WeatherForecast',
    title: 'Weather Forecast',
    audioPath: 'audio/Weatherannounce.wav',
    scriptPath: 'assets/subtitles/Weatherannounce.json',
    level: 'Starter',
    tag: 'Weather',
    durationSec: 6,
    wordCount: 50,
  ),
  PracticeMaterial(
    id: 'introduction',
    title: 'Introduction',
    audioPath: 'audio/introduction.wav',
    scriptPath: 'assets/subtitles/introduction.json',
    level: 'Starter',
    tag: 'Intro',
    durationSec: 4,
    wordCount: 38,
  ),
  PracticeMaterial(
    id: 'SchoolAnnouncement',
    title: 'School Announcement',
    audioPath: 'audio/school_announcement.wav',
    scriptPath: 'assets/subtitles/school_announcement.json',
    level: 'Basic',
    tag: 'School',
    durationSec: 6,
    wordCount: 58,
  ),
  PracticeMaterial(
    id: 'Weather',
    title: 'Weather',
    audioPath: 'audio/weather.wav',
    scriptPath: 'assets/subtitles/weather.json',
    level: 'Intermediate',
    tag: 'Weather',
    durationSec: 5,
    wordCount: 65,
  ),
];
