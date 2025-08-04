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
      return 'Advanced';
    case '最上級':
    case '最上級（〜300語）':
      return 'Master';
    default:
      return level;
  }
}

List<PracticeMaterial> allMaterials = [
  // Level 1 - Starter
  PracticeMaterial(
    id: 'Studying_Every_Day',
    title: 'Studying Every Day',
    audioPath: 'audio/Level1/Study_Exam/Studying_Every_Day.wav',
    scriptPath: 'assets/subtitles/Level1/Study_Exam/Studying_Every_Day.json',
    level: 'Starter',
    tag: 'Study_Exam',
    durationSec: 13,
    wordCount: 30,
  ),
  PracticeMaterial(
    id: 'Introducing_Myself_at_Work',
    title: 'Introducing Myself at Work',
    audioPath: 'audio/Level1/Business/Introducing_Myself_at_Work.wav',
    scriptPath:
        'assets/subtitles/Level1/Business/Introducing_Myself_at_Work.json',
    level: 'Starter',
    tag: 'Business',
    durationSec: 8,
    wordCount: 31,
  ),
  PracticeMaterial(
    id: 'My_morning_Routine',
    title: 'My Morning Routine',
    audioPath: 'audio/Level1/DailyLife/My_morning_Routine.wav',
    scriptPath: 'assets/subtitles/Level1/DailyLife/My_morning_Routine.json',
    level: 'Starter',
    tag: 'DailyLife',
    durationSec: 19,
    wordCount: 50,
  ),
  PracticeMaterial(
    id: 'Simple_Station_Announcement',
    title: 'Simple Station Announcement',
    audioPath: 'audio/Level1/Announcement/Simple_Station_Announcement.wav',
    scriptPath:
        'assets/subtitles/Level1/Announcement/Simple_Station_Announcement.json',
    level: 'Starter',
    tag: 'Announcement',
    durationSec: 8,
    wordCount: 30,
  ),

  // Level 2 - Basic
  PracticeMaterial(
    id: 'Starting_a_Simple_Morning_Stretch',
    title: 'Starting a Simple Morning Stretch',
    audioPath:
        'audio/Level2/Lifestyle_Health/Starting_a_Simple_Morning_Stretch.wav',
    scriptPath:
        'assets/subtitles/Level2/Lifestyle_Health/Starting_a_Simple_Morning_Stretch.json',
    level: 'Basic',
    tag: 'Lifestyle_Health',
    durationSec: 18,
    wordCount: 58,
  ),
  PracticeMaterial(
    id: 'Setting_Goals',
    title: 'Setting Goals',
    audioPath: 'audio/Level2/Study_Exam/Setting_Goals.wav',
    scriptPath: 'assets/subtitles/Level2/Study_Exam/Setting_Goals.json',
    level: 'Basic',
    tag: 'Study_Exam',
    durationSec: 16,
    wordCount: 60,
  ),
  PracticeMaterial(
    id: 'My_Daily_Tasks',
    title: 'My Daily Tasks',
    audioPath: 'audio/Level2/Business/My_Daily_Tasks.wav',
    scriptPath: 'assets/subtitles/Level2/Business/My_Daily_Tasks.json',
    level: 'Basic',
    tag: 'Business',
    durationSec: 16,
    wordCount: 62,
  ),
  PracticeMaterial(
    id: 'Going_to_the_Supermarket',
    title: 'Going to the Supermarket',
    audioPath: 'audio/Level2/DailyLife/Going_to_the_Supermarket.wav',
    scriptPath:
        'assets/subtitles/Level2/DailyLife/Going_to_the_Supermarket.json',
    level: 'Basic',
    tag: 'DailyLife',
    durationSec: 27,
    wordCount: 78,
  ),
  PracticeMaterial(
    id: 'Platform_Change_Notice',
    title: 'Platform Change Notice',
    audioPath: 'audio/Level2/Announcement/Platform_Change_Notice.wav',
    scriptPath:
        'assets/subtitles/Level2/Announcement/Platform_Change_Notice.json',
    level: 'Basic',
    tag: 'Announcement',
    durationSec: 15,
    wordCount: 58,
  ),

  // Level 3 - Intermediate
  PracticeMaterial(
    id: 'How_I_Stay_Healthy_at_Work',
    title: 'How I Stay Healthy at Work',
    audioPath: 'audio/Level3/Lifestyle_Health/How_I_Stay_Healthy_at_Work.wav',
    scriptPath:
        'assets/subtitles/Level3/Lifestyle_Health/How_I_Stay_Healthy_at_Work.json',
    level: 'Intermediate',
    tag: 'Lifestyle_Health',
    durationSec: 23,
    wordCount: 71,
  ),
  PracticeMaterial(
    id: 'A_New_Study_Habit',
    title: 'A New Study Habit',
    audioPath: 'audio/Level3/Study_Exam/A_New_Study_Habit.wav',
    scriptPath: 'assets/subtitles/Level3/Study_Exam/A_New_Study_Habit.json',
    level: 'Intermediate',
    tag: 'Study_Exam',
    durationSec: 22,
    wordCount: 70,
  ),
  PracticeMaterial(
    id: 'Phone_Call_to_a_Client',
    title: 'Phone Call to a Client',
    audioPath: 'audio/Level3/Business/Phone_Call_to_a_Client.wav',
    scriptPath: 'assets/subtitles/Level3/Business/Phone_Call_to_a_Client.json',
    level: 'Intermediate',
    tag: 'Business',
    durationSec: 19,
    wordCount: 78,
  ),
  PracticeMaterial(
    id: 'A_Busy_Morning_Routine',
    title: 'A Busy Morning Routine',
    audioPath: 'audio/Level3/DailyLife/A_Busy_Morning_Routine.wav',
    scriptPath: 'assets/subtitles/Level3/DailyLife/A_Busy_Morning_Routine.json',
    level: 'Intermediate',
    tag: 'DailyLife',
    durationSec: 33,
    wordCount: 99,
  ),
  PracticeMaterial(
    id: 'Delay_Due_to_Wather',
    title: 'Delay Due to Weather',
    audioPath: 'audio/Level3/Announcement/Delay_Due_to_Wather.wav',
    scriptPath: 'assets/subtitles/Level3/Announcement/Delay_Due_to_Wather.json',
    level: 'Intermediate',
    tag: 'Announcement',
    durationSec: 19,
    wordCount: 74,
  ),

  // Level 4 - Advanced
  PracticeMaterial(
    id: 'Creating_a_Balanced_Daily_Routine',
    title: 'Creating a Balanced Daily Routine',
    audioPath:
        'audio/Level4/Lifestyle_Health/Creating_a_Balanced_Daily_Routine.wav',
    scriptPath:
        'assets/subtitles/Level4/Lifestyle_Health/Creating_a_Balanced_Daily_Routine.json',
    level: 'Advanced',
    tag: 'Lifestyle_Health',
    durationSec: 37,
    wordCount: 121,
  ),
  PracticeMaterial(
    id: 'The_Story_of_Heken_Keller',
    title: 'The Story of Helen Keller',
    audioPath: 'audio/Level4/Study_Exam/The_Story_of_Heken_Keller.wav',
    scriptPath:
        'assets/subtitles/Level4/Study_Exam/The_Story_of_Heken_Keller.json',
    level: 'Advanced',
    tag: 'Study_Exam',
    durationSec: 41,
    wordCount: 118,
  ),
  PracticeMaterial(
    id: 'Preparing_for_a_Job_Interview',
    title: 'Preparing for a Job Interview',
    audioPath: 'audio/Level4/Business/Preparing_for_a_Job_Interview.wav',
    scriptPath:
        'assets/subtitles/Level4/Business/Preparing_for_a_Job_Interview.json',
    level: 'Advanced',
    tag: 'Business',
    durationSec: 30,
    wordCount: 122,
  ),
  PracticeMaterial(
    id: 'Handling_Unexpected_Problems_at_Work',
    title: 'Handling Unexpected Problems at Work',
    audioPath:
        'audio/Level4/DailyLife/Handling_Unexpected_Problems_at_Work.wav',
    scriptPath:
        'assets/subtitles/Level4/DailyLife/Handling_Unexpected_Problems_at_Work.json',
    level: 'Advanced',
    tag: 'DailyLife',
    durationSec: 45,
    wordCount: 129,
  ),
  PracticeMaterial(
    id: 'Train_Maintenance_Announcement',
    title: 'Train Maintenance Announcement',
    audioPath: 'audio/Level4/Announcement/Train_Maintenance_Announcement.wav',
    scriptPath:
        'assets/subtitles/Level4/Announcement/Train_Maintenance_Announcement.json',
    level: 'Advanced',
    tag: 'Announcement',
    durationSec: 29,
    wordCount: 122,
  ),

  // Level 5 - Master
  PracticeMaterial(
    id: 'The_Self_Education_Of_Soichiro_Honda',
    title: 'The Self-Education of Soichiro Honda',
    audioPath:
        'audio/Level5/Study_Exam/The_Self_Education_Of_Soichiro_Honda.wav',
    scriptPath:
        'assets/subtitles/Level5/Study_Exam/The_Self_Education_Of_Soichiro_Honda.json',
    level: 'Master',
    tag: 'Study_Exam',
    durationSec: 60,
    wordCount: 150,
  ),
  PracticeMaterial(
    id: 'Negotiating_with_an_International_Client',
    title: 'Negotiating with an International Client',
    audioPath:
        'audio/Level5/Business/Negotiating_with_an_International_Client.wav',
    scriptPath:
        'assets/subtitles/Level5/Business/Negotiating_with_an_International_Client.json',
    level: 'Master',
    tag: 'Business',
    durationSec: 49,
    wordCount: 150,
  ),
  PracticeMaterial(
    id: 'Balancing_Work_and_Personal_Life',
    title: 'Balancing Work and Personal Life',
    audioPath: 'audio/Level5/DailyLife/Balancing_Work_and_Personal_Life.wav',
    scriptPath:
        'assets/subtitles/Level5/DailyLife/Balancing_Work_and_Personal_Life.json',
    level: 'Master',
    tag: 'DailyLife',
    durationSec: 52,
    wordCount: 151,
  ),
  PracticeMaterial(
    id: 'Emergency_Train_Delay_Announcement',
    title: 'Emergency Train Delay Announcement',
    audioPath:
        'audio/Level5/Announcement/Emergency_Train_Delay_Announcement.wav',
    scriptPath:
        'assets/subtitles/Level5/Announcement/Emergency_Train_Delay_Announcement.json',
    level: 'Master',
    tag: 'Announcement',
    durationSec: 46,
    wordCount: 151,
  ),
];
