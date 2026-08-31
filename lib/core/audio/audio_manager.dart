import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

class AudioManager {
  // Players for different types of audio
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  AudioManager() {
    _init();
  }

  void _init() async {
    // Configure players
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _voicePlayer.setReleaseMode(ReleaseMode.stop);
  }

  // Play background suspense/heartbeat
  Future<void> playHeartbeat() async {
    try {
      await _musicPlayer.play(AssetSource('audio/heartbeat.mp3'), volume: 0.5);
    } catch (e) {
      // Ignore if file doesn't exist yet
    }
  }
  
  Future<void> playNightMusic() async {
    try {
      await _musicPlayer.play(AssetSource('audio/night_music.mp3'), volume: 0.3);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  // Play SFX (Gunshot, etc)
  Future<void> playGunshot() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/gunshot.mp3'), volume: 1.0);
    } catch (e) {
      // Ignore
    }
  }
  
  Future<void> playSuccess() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/success.mp3'), volume: 1.0);
    } catch (e) {
      // Ignore
    }
  }

  // Play Voiceovers
  Future<void> playVoiceover(String filename) async {
    try {
      await _voicePlayer.play(AssetSource('audio/$filename'), volume: 1.0);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> stopVoiceover() async {
    await _voicePlayer.stop();
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    _voicePlayer.dispose();
  }
}
