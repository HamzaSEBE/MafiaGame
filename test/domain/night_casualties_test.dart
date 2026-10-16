import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

final at = DateTime(2026, 10, 13);
GameEvent action(
  EventType type,
  String actor,
  String target, {
  String game = 'news',
}) => GameEvent(
  id: '$type-$actor-$target',
  gameId: game,
  round: 3,
  phase: Phase.night,
  type: type,
  actorId: actor,
  targetId: target,
  timestamp: at,
);
GameState resolve(List<GameEvent> events) => NightResolutionEngine.resolve(
  GameState(
    id: 'news',
    round: 3,
    phase: Phase.night,
    players: [
      for (final (id, role) in [
        ('m', Role.normalMafia),
        ('s', Role.goodCitizen),
        ('d', Role.citizensGirl),
        ('c', Role.goodCitizen),
      ])
        Player(id: id, name: id, role: role, createdAt: at),
    ],
    eventHistory: events,
  ),
  const GameRuleset(),
  timestamp: at,
);
NightCasualties casualties(GameState state) =>
    NightCasualties(state.eventHistory.last, state.eventHistory);
String narrative(GameState state) =>
    TimelineGenerator.generateNarrative(state, 'المواطنين');

void main() {
  test('QR sniper self-selection still skips without recording a shot', () {
    final base = resolve([]).copyWith(
      eventHistory: [],
      rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
      players: [
        for (final p in resolve([]).players) p.copyWith(hasSniper: p.id == 's'),
      ],
    );
    final result = ServerReducer.transition(
      base,
      'closeNight',
      [
        {'seatId': 's', 'actionType': 'sniperKill', 'targetId': 's'},
        {'seatId': 'm', 'actionType': 'assassination', 'targetId': 'c'},
        {'seatId': 'd', 'actionType': 'protection', 'targetId': 'c'},
      ],
      at,
      'skip-sniper',
    );
    expect(
      result.eventHistory.any((e) => e.type == EventType.sniperKill),
      isFalse,
    );
    expect(result.getPlayerById('s')!.isAlive, isTrue);
    expect(
      InteractivePrompts.night(result)['s']!.any((p) => p.type == 'sniperKill'),
      isTrue,
    );
  });
  test('sniper-only death is never described as a Mafia assassination', () {
    final state = resolve([action(EventType.sniperKill, 's', 'm')]);
    expect(casualties(state).sniper, {'m'});
    expect(casualties(state).mafia, isEmpty);
    expect(narrative(state), contains('ضحية القنص:'));
    expect(narrative(state), isNot(contains('اغتيال المافيا:')));
  });
  test('two different victims retain their actual cause', () {
    final state = resolve([
      action(EventType.assassination, 'm', 'c'),
      action(EventType.sniperKill, 's', 'm'),
    ]);
    expect(casualties(state).mafia, {'c'});
    expect(casualties(state).sniper, {'m'});
    expect(narrative(state), contains('سقط (c) ضحية للمافيا'));
    expect(narrative(state), contains('رصاصة القنّاص (m)'));
  });
  test('a protected sniper target is not a sniper victim', () {
    final state = resolve([
      action(EventType.assassination, 'm', 'c'),
      action(EventType.sniperKill, 's', 'm'),
      action(EventType.protection, 'd', 'm'),
    ]);
    expect(casualties(state).sniper, isEmpty);
    expect(casualties(state).mafia, {'c'});
    expect(narrative(state), isNot(contains('ضحية القنص:')));
    expect(narrative(state), contains('إنقاذ (m)'));
  });
  test(
    'a victim hit by both causes belongs to both without inventing another death',
    () {
      final state = resolve([
        action(EventType.assassination, 'm', 'c'),
        action(EventType.sniperKill, 's', 'c'),
      ]);
      expect(casualties(state).mafia, {'c'});
      expect(casualties(state).sniper, {'c'});
      expect(casualties(state).unknown, isEmpty);
      expect(state.eventHistory.last.metadata['assassinatedIds'], ['c']);
    },
  );
  test('old summaries reconstruct causes only from this game and round', () {
    final state = resolve([
      action(EventType.assassination, 'm', 'c'),
      action(EventType.sniperKill, 's', 'm'),
    ]);
    final oldSummary = GameEvent(
      id: 'old',
      gameId: 'news',
      round: 3,
      phase: Phase.nightResolution,
      type: EventType.nightResolutionSummary,
      timestamp: at,
      metadata: {
        'assassinatedIds': ['c', 'm'],
      },
    );
    final report = NightCasualties(oldSummary, [
      ...state.eventHistory,
      action(EventType.assassination, 'm', 'm', game: 'other'),
    ]);
    expect(report.mafia, {'c'});
    expect(report.sniper, {'m'});
    expect(report.unknown, isEmpty);
  });
  test(
    'unrecorded legacy death gets a neutral title instead of a false cause',
    () {
      final summary = GameEvent(
        id: 'old',
        gameId: 'news',
        round: 3,
        phase: Phase.nightResolution,
        type: EventType.nightResolutionSummary,
        timestamp: at,
        metadata: {
          'assassinatedIds': ['c'],
        },
      );
      final state = resolve([]).copyWith(eventHistory: [summary]);
      expect(casualties(state).unknown, {'c'});
      expect(narrative(state), contains('ضحايا الليل:'));
      expect(narrative(state), isNot(contains('اغتيال المافيا:')));
    },
  );
  test('a fully protected night has no victims of either cause', () {
    final state = resolve([
      action(EventType.sniperKill, 's', 'm'),
      action(EventType.protection, 'd', 'm'),
    ]);
    expect(casualties(state).isEmpty, isTrue);
    expect(narrative(state), contains('لم يُسفك أي دم'));
  });
}
