import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mafia_nightfall/data/repositories/checkpoints/local_checkpoint_repository.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final Map<String, Object> data = {};
  MemoryPreferences({this.delay});
  final Completer<void>? delay;
  @override
  Future<String?> getString(String key) async => data[key] as String?;
  @override
  Future<List<String>?> getStringList(String key) async =>
      data[key] as List<String>?;
  @override
  Future<void> setString(String key, String value) async {
    if (delay != null) await delay!.future;
    data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final active = GameState(
  id: 'game-a',
  phase: Phase.day,
  players: [
    Player(
      id: 'p',
      name: 'Player',
      role: Role.goodCitizen,
      createdAt: DateTime(2026),
    ),
  ],
);

void main() {
  test(
    'accidental restart resumes the same game for the same account only',
    () async {
      final prefs = MemoryPreferences();
      await LocalCheckpointRepository(preferences: prefs).save('a', active);
      final restarted = LocalCheckpointRepository(preferences: prefs);
      expect((await restarted.load('a'))?.id, active.id);
      expect(await restarted.load('b'), isNull);
    },
  );
  test(
    'setup with retained players and a completed game do not offer continue',
    () async {
      final repo = LocalCheckpointRepository(preferences: MemoryPreferences());
      await repo.save('a', active);
      await repo.save('a', active.copyWith(phase: Phase.setup));
      expect(await repo.load('a'), isNull);
      await repo.save('a', active.copyWith(phase: Phase.winCheck));
      expect(await repo.load('a'), isNull);
    },
  );
  test(
    'manual end clears pending saves and rejects late stale saves after restart',
    () async {
      final prefs = MemoryPreferences(delay: Completer<void>());
      final repo = LocalCheckpointRepository(preferences: prefs);
      final save = repo.save('a', active);
      await Future<void>.delayed(Duration.zero);
      final clear = repo.clear('a', active.id);
      prefs.delay!.complete();
      await save;
      await clear;
      expect(await repo.load('a'), isNull);
      final restarted = LocalCheckpointRepository(preferences: prefs);
      expect(await restarted.wasEnded('a', active.id), true);
      await restarted.save('a', active);
      expect(await restarted.load('a'), isNull);
      await restarted.save('a', active.copyWith(id: 'new-game'));
      expect((await restarted.load('a'))?.id, 'new-game');
    },
  );
}
