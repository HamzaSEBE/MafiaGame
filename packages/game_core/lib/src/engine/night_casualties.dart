import '../events/game_event.dart';

/// Reports actual resolved deaths, including summaries saved by older versions.
/// A blocked shot is an attempt, not a casualty. One player can be hit by both.
class NightCasualties {
  NightCasualties(GameEvent summary, Iterable<GameEvent> events) {
    final metadata = summary.metadata;
    final resolved =
        (metadata['assassinatedIds'] as List?)?.whereType<String>().toSet() ??
        <String>{};
    Set<String> causedBy(String key, EventType type) {
      final recorded = metadata[key];
      if (recorded is List) {
        return recorded.whereType<String>().where(resolved.contains).toSet();
      }
      return events
          .where(
            (e) =>
                e.gameId == summary.gameId &&
                e.round == summary.round &&
                e.type == type &&
                resolved.contains(e.targetId),
          )
          .map((e) => e.targetId!)
          .toSet();
    }

    mafia = Set.unmodifiable(causedBy('mafiaDeadIds', EventType.assassination));
    sniper = Set.unmodifiable(causedBy('sniperDeadIds', EventType.sniperKill));
    unknown = Set.unmodifiable(resolved.difference({...mafia, ...sniper}));
  }
  late final Set<String> mafia;
  late final Set<String> sniper;
  late final Set<String> unknown;
  bool get isEmpty => mafia.isEmpty && sniper.isEmpty && unknown.isEmpty;
}
