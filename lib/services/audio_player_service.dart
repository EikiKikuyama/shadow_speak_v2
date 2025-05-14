import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  /// 汎用再生（Listeningモード用） → asset or URL
  Future<void> play(String sourcePath) async {
    await _player.stop(); // 再生中なら停止
    await _player.play(AssetSource(sourcePath));
  }

  /// 録音ファイルなどローカル再生（Shadowingモードなど用）
  Future<void> playLocalFile(String filePath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> reset() async {
    await _player.seek(Duration.zero);
  }

  void dispose() {
    _player.dispose();
  }
}
