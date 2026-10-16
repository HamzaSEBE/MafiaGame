import 'package:game_core/src/engine/citizen_boy_engine.dart';
import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/entities/interactive/models.dart';
import 'package:game_core/src/enums/role.dart';
import 'package:game_core/src/events/game_event.dart';

/// The host UI and security documents use the same target/ability policy.
abstract final class InteractivePrompts {
  static Map<String, List<PlayerActionPrompt>> voting(GameState state) => {
    for (final player in state.alivePlayers)
      player.id: [
        PlayerActionPrompt(
          type: 'vote',
          availableTargets: state.alivePlayers
              .where((target) => target.id != player.id)
              .map((p) => p.id)
              .toList(),
        ),
      ],
  };

  static Map<String, List<PlayerActionPrompt>> retaliation(GameState state) {
    final actor = CitizenBoyEngine.pendingActor(state);
    if (actor == null || state.alivePlayers.isEmpty) return {};
    return {
      actor.id: [
        PlayerActionPrompt(
          type: 'retaliation',
          availableTargets: state.alivePlayers.map((p) => p.id).toList(),
        ),
      ],
    };
  }

  static Map<String, List<PlayerActionPrompt>> night(GameState state) {
    final prompts = <String, List<PlayerActionPrompt>>{};
    final alive = state.alivePlayers;
    final ids = alive.map((p) => p.id).toList();
    final counts = <EventType, Map<String, Map<String, int>>>{};
    final shots = <String>{};
    for (final event in state.eventHistory) {
      if (event.gameId != state.id || event.actorId == null) continue;
      if (event.type == EventType.sniperKill) shots.add(event.actorId!);
      if ((event.type == EventType.silence ||
              event.type == EventType.protection) &&
          event.targetId != null) {
        final targets = counts
            .putIfAbsent(event.type, () => {})
            .putIfAbsent(event.actorId!, () => {});
        targets.update(event.targetId!, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    void add(String actor, String type, List<String> targets) {
      if (targets.isNotEmpty) {
        (prompts[actor] ??= []).add(
          PlayerActionPrompt(type: type, availableTargets: targets),
        );
      }
    }

    List<String> limitedTargets(String actor, EventType type, int limit) => ids
        .where((id) => limit == -1 || (counts[type]?[actor]?[id] ?? 0) < limit)
        .toList();
    final killer =
        alive.where((p) => p.role == Role.mafiaSheikh).firstOrNull ??
        alive.where((p) => p.role == Role.mafiaGirl).firstOrNull ??
        alive.where((p) => p.role == Role.normalMafia).firstOrNull;
    if (killer != null) {
      add(
        killer.id,
        'assassination',
        alive.where((p) => p.role.team != Team.mafia).map((p) => p.id).toList(),
      );
    }
    for (final player in alive) {
      switch (player.role) {
        case Role.mafiaGirl:
          add(
            player.id,
            'silence',
            limitedTargets(
              player.id,
              EventType.silence,
              state.rules.abilityRules.silenceTargetLimit,
            ),
          );
        case Role.citizensGirl:
          add(
            player.id,
            'protection',
            limitedTargets(
              player.id,
              EventType.protection,
              state.rules.abilityRules.protectionTargetLimit,
            ),
          );
        case Role.citizensSheikh:
          add(
            player.id,
            'investigation',
            ids.where((id) => id != player.id).toList(),
          );
        default:
          break;
      }
      if (state.rules.abilityRules.sniper &&
          player.hasSniper &&
          player.role.team == Team.citizens &&
          !shots.contains(player.id)) {
        // Choosing oneself means skip, without consuming the one sniper shot.
        add(player.id, 'sniperKill', ids);
      }
      if (!prompts.containsKey(player.id)) add(player.id, 'sleep', [player.id]);
    }
    return prompts;
  }

  static List<ActionRequest> currentActions(
    List<ActionRequest> actions,
    int? revision,
  ) => actions
      .where((action) => revision != null && action.revision == revision)
      .toList();
}
