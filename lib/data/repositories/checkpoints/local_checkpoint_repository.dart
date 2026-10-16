import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';

/// Best-effort local recovery. Interactive games restore from the host-only
/// Firestore checkpoint; preference storage is never their authoritative state.
class LocalCheckpointRepository {
  LocalCheckpointRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  final Map<String, Future<void>> _writes = {};
  final Map<String, Set<String>> _ended = {};
  String _endedKey(String uid) => 'mafia.ended.v1.$uid';
  String _key(String uid) => 'mafia.checkpoint.v1.$uid';
  Future<GameState?> load(String uid) async {
    await (_writes[uid] ?? Future<void>.value()).catchError((Object _) {});
    final raw = await _preferences.getString(_key(uid));
    if (raw == null || raw.length > 1000000) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['schemaVersion'] != 1 || data['uid'] != uid) return null;
      final state = GameState.fromJson(
        Map<String, dynamic>.from(data['state'] as Map),
      );
      if (!_recoverable(state) || await wasEnded(uid, state.id)) return null;
      return state;
    } catch (_) {
      return null;
    }
  }

  bool _recoverable(GameState state) =>
      state.players.isNotEmpty &&
      state.phase != Phase.setup &&
      state.phase != Phase.winCheck;

  Future<bool> wasEnded(String uid, String gameId) async {
    if (_ended[uid]?.contains(gameId) == true) return true;
    final ids =
        await _preferences.getStringList(_endedKey(uid)) ?? const <String>[];
    return ids.contains(gameId);
  }

  /// Ordered after pending saves; the tombstone also blocks stale callbacks and
  /// an old interactive pointer from offering a manually ended game again.
  Future<void> clear(String uid, String gameId) {
    (_ended[uid] ??= {}).add(gameId);
    final operation = (_writes[uid] ?? Future<void>.value())
        .catchError((Object _) {})
        .then((_) async {
          final ids =
              (await _preferences.getStringList(_endedKey(uid)) ?? <String>[])
                  .where((id) => id != gameId)
                  .toList()
                ..add(gameId);
          await _preferences.setStringList(
            _endedKey(uid),
            ids.skip(ids.length > 100 ? ids.length - 100 : 0).toList(),
          );
          await _preferences.remove(_key(uid));
        });
    _writes[uid] = operation;
    return operation.whenComplete(() {
      if (identical(_writes[uid], operation)) _writes.remove(uid);
    });
  }

  Future<void> save(String uid, GameState state) {
    final operation = (_writes[uid] ?? Future<void>.value())
        .catchError((Object _) {})
        .then((_) async {
          if (!_recoverable(state)) {
            await _preferences.remove(_key(uid));
            return;
          }
          if (await wasEnded(uid, state.id)) return;
          final data = jsonEncode({
            'schemaVersion': 1,
            'uid': uid,
            'savedAt': DateTime.now().toUtc().toIso8601String(),
            'state': state.toJson(),
          });
          if (utf8.encode(data).length > 700000) {
            throw StateError('حجم الحفظ المحلي تجاوز الحد الآمن.');
          }
          await _preferences.setString(_key(uid), data);
        });
    _writes[uid] = operation;
    return operation.whenComplete(() {
      if (identical(_writes[uid], operation)) _writes.remove(uid);
    });
  }
}

final localCheckpointRepositoryProvider = Provider(
  (ref) => LocalCheckpointRepository(),
);
