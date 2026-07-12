import 'package:just_audio/just_audio.dart';

/// Plays Malayalam TTS audio prompts from assets.
class TtsService {
  final AudioPlayer _player = AudioPlayer();

  /// Play a TTS prompt from the assets folder.
  Future<void> play(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (_) {
      // Audio file may not exist yet — fail silently during development
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  bool get isPlaying => _player.playing;

  void dispose() => _player.dispose();
}
