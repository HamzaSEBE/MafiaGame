import 'dart:io';

void main() {
  final file = File('lib/core/audio/audio_manager.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('AudioPlayer _ambiencePlayer')) {
    final oldVars = """
class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioManager() {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }
""";
    
    final newVars = """
class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _ambiencePlayer = AudioPlayer();

  AudioManager() {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Start playing wind/night ambient sounds (No music)
  Future<void> startAmbience() async {
    try {
      if (_ambiencePlayer.state != PlayerState.playing) {
        await _ambiencePlayer.play(AssetSource('audio/ambience.wav'), volume: 0.6);
      }
    } catch (_) {}
  }

  /// Stop ambience
  Future<void> stopAmbience() async {
    try {
      await _ambiencePlayer.stop();
    } catch (_) {}
  }
""";

    content = content.replaceFirst(oldVars, newVars);
    
    final oldDispose = """
  void dispose() {
    _sfxPlayer.dispose();
  }
""";
    final newDispose = """
  void dispose() {
    _sfxPlayer.dispose();
    _ambiencePlayer.dispose();
  }
""";
    content = content.replaceFirst(oldDispose, newDispose);
    
    file.writeAsStringSync(content);
    print('AudioManager updated with Ambience support!');
  }
}