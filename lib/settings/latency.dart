// lib/settings/latency.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 端末既定値（暫定）：iOS 60ms / Android 40ms くらい
int _defaultLag() => Platform.isIOS ? 60 : 40;

/// まずは隠しパラメータとして持つ（必要になったら設定画面に出す）
final lagMsProvider = StateProvider<int>((ref) => _defaultLag());
