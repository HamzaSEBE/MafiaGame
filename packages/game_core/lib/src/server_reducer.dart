import 'game_machine.dart';
import 'entities/game_state.dart';
import 'entities/interactive/models.dart';
import 'enums/phase.dart';
import 'enums/role.dart';
import 'events/game_event.dart';
import 'engine/citizen_boy_engine.dart';
import 'policy/interactive_prompts.dart';

/// Consumes validated server actions and a moderator intent; never client state.
abstract final class ServerReducer {
  static GameState transition(
    GameState state,
    String command,
    List<Map<String, dynamic>> actions,
    DateTime at,
    String commandId,
  ) {
    var sequence = 0;
    final g = GameMachine(
      state,
      clock: () => at,
      nextId: () => '$commandId:${sequence++}',
    );
    switch (command) {
      case 'beginIntroductionNight':
        _require(state.phase == Phase.roleReveal);
        g.beginIntroductionNight();
      case 'skipIntroductionNight':
        _require(
          state.phase == Phase.roleReveal ||
              (state.phase == Phase.night && state.round == 1),
        );
        g.skipIntroductionNight();
      case 'startVoting':
        _require(state.phase == Phase.day);
        g.startVoting();
      case 'openNightActions':
        _require(
          state.phase == Phase.elimination || state.phase == Phase.night,
        );
        if (state.phase == Phase.elimination) g.advanceToNight();
      case 'closeNight':
        _require(state.phase == Phase.night && state.round > 1);
        final prompts = InteractivePrompts.night(state);
        final sorted = List<Map<String, dynamic>>.from(actions)
          ..sort(
            (a, b) => '${a['seatId']}:${a['actionType']}'.compareTo(
              '${b['seatId']}:${b['actionType']}',
            ),
          );
        final seen = <String>{};
        for (final action in sorted) {
          final actor = action['seatId'] as String;
          final type = action['actionType'] as String;
          final target = action['targetId'] as String;
          if (!seen.add('$actor:$type') ||
              prompts[actor]?.any(
                    (p) =>
                        p.type == type && p.availableTargets.contains(target),
                  ) !=
                  true) {
            throw StateError('Invalid frozen action');
          }
          if (type == 'sleep' || (type == 'sniperKill' && actor == target)) {
            continue;
          }
          g.submitNightAction(
            actorId: actor,
            targetId: target,
            type: EventType.values.byName(type),
          );
        }
        g.resolveNight();
      case 'closeVote':
        _require(state.phase == Phase.voting);
        final prompts = InteractivePrompts.voting(state);
        final votes = <String, String>{};
        for (final action in actions.where((a) => a['actionType'] == 'vote')) {
          final actor = action['seatId'] as String,
              target = action['targetId'] as String;
          if (prompts[actor]?.first.availableTargets.contains(target) != true) {
            throw StateError('Invalid ballot');
          }
          votes[actor] = target;
        }
        g.submitFinalVotes(votes);
        g.resolveVote();
      case 'revote':
        _require(state.phase == Phase.voting);
        g.revote();
      case 'skipVote':
        _require(state.phase == Phase.voting || state.phase == Phase.day);
        g.skipElimination();
      case 'retaliation':
        _require(state.phase == Phase.triggeredAbility);
        final actor = CitizenBoyEngine.pendingActor(state);
        final action = actions
            .where(
              (a) =>
                  a['actionType'] == 'retaliation' && a['seatId'] == actor?.id,
            )
            .firstOrNull;
        if (actor == null || action == null) {
          throw StateError('Missing retaliation');
        }
        g.citizenBoyRetaliation(
          actorId: actor.id,
          targetId: action['targetId'] as String,
          nextPhase: _afterRetaliation(state),
        );
      case 'skipAbility':
        _require(state.phase == Phase.triggeredAbility);
        g.skipTriggeredAbility(_afterRetaliation(state));
      default:
        throw ArgumentError('Unknown transition');
    }
    return g.state;
  }

  static Phase _afterRetaliation(GameState state) {
    final event = state.eventHistory
        .where(
          (e) =>
              e.type == EventType.elimination ||
              e.type == EventType.nightResolutionSummary,
        )
        .lastOrNull;
    return event?.type == EventType.elimination ? Phase.night : Phase.day;
  }

  static void _require(bool condition) {
    if (!condition) throw StateError('Wrong phase');
  }

  static Map<String, dynamic> project(
    GameState state,
    int revision, {
    bool nightActions = true,
  }) {
    final prompts = switch (state.phase) {
      Phase.voting => InteractivePrompts.voting(state),
      Phase.night when nightActions && state.round > 1 =>
        InteractivePrompts.night(state),
      Phase.triggeredAbility => InteractivePrompts.retaliation(state),
      _ => <String, List<PlayerActionPrompt>>{},
    };
    return {
      'phase': state.phase.name,
      'round': state.round,
      'winner': state.winner?.name,
      'actionsPhase': prompts.isEmpty ? null : state.phase.name,
      'actionsRound': prompts.isEmpty ? null : state.round,
      'seats': {
        for (final p in state.players)
          p.id: {
            'id': p.id,
            'playerName': p.name,
            'isAlive': p.isAlive,
            'isCitizenSheikhRevealed': p.isCitizenSheikhRevealed,
          },
      },
      'secrets': {
        for (final p in state.players)
          p.id: {
            ...InteractiveSecret(
              id: p.id,
              role: p.role,
              promptRevision: revision,
              requiredActions: prompts[p.id] ?? [],
              isSniper: p.hasSniper,
              mafiaTeammates: p.role.team == Team.mafia
                  ? state.players
                        .where(
                          (other) =>
                              other.role.team == Team.mafia && other.id != p.id,
                        )
                        .map((other) => other.name)
                        .toList()
                  : [],
            ).toJson(),
            'canReveal':
                p.role == Role.citizensSheikh &&
                state.rules.abilityRules.citizenSheikhReveal,
          },
      },
    };
  }
}
