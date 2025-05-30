import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<File> loadAssetAsFile(String assetPath, String filename) async {
  final byteData = await rootBundle.load(assetPath);
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$filename');
  return await tempFile.writeAsBytes(
    byteData.buffer.asUint8List(),
    flush: true,
  );
}
