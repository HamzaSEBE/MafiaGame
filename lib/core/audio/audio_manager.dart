import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioManager() {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// نقرة زر عادية
  Future<void> playClick() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/click.wav'), volume: 0.9);
    } catch (_) {}
  }

  /// مؤثر الاغتيال - صوت عميق ومرعب
  Future<void> playKill() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/kill.wav'), volume: 1.0);
    } catch (_) {}
  }

  /// مؤثر الحماية - صوت درع لطيف
  Future<void> playProtect() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/protect.wav'), volume: 1.0);
    } catch (_) {}
  }

  /// مؤثر التصويت - نغمة تصاعدية مثيرة
  Future<void> playVote() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/vote.wav'), volume: 0.8);
    } catch (_) {}
  }

  /// مؤثر كشف الدور
  Future<void> playReveal() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/reveal.wav'), volume: 0.9);
    } catch (_) {}
  }

  /// مؤثر الافتتاحية
  Future<void> playSplashIntro() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/intro.wav'), volume: 1.0);
    } catch (_) {}
  }

  /// تشغيل أصوات الحكم (اختياري - لو حبيت تضيف)
  Future<void> playVoiceover(String filename) async {
    try {
      await _sfxPlayer.play(AssetSource('audio/$filename'), volume: 1.0);
    } catch (_) {}
  }

  void dispose() {
    _sfxPlayer.dispose();
  }
}
