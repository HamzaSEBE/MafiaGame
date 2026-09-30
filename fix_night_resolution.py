import re

with open('lib/domain/engine/night_resolution_engine.dart', 'r') as f:
    content = f.read()

old_logic = """    // 5. Calculate deaths
    final deadPlayerIds = <String>{};
    for (var targetId in finalAssassinationTargets) {
      if (!protectedTargetIds.contains(targetId)) {
        deadPlayerIds.add(targetId);
      }
    }

    // 6. Calculate silences
    final silencedPlayerIds = silences.map((e) => e.targetId!).toSet();

    // 7. Update players
    final updatedPlayers = state.players.map((p) {
      bool isAlive = p.isAlive;
      bool isSilenced = silencedPlayerIds.contains(p.id);

      if (deadPlayerIds.contains(p.id)) {
        isAlive = false;
      }

      // If a player died, they shouldn't be silenced (or it doesn't matter, but let's clear it)
      if (!isAlive) {
        isSilenced = false;
      }

      // If they were already silenced from previous rounds, clear it unless re-silenced.
      // Wait, silence applies for the NEXT day. So anyone targeted by silence tonight is silenced tomorrow.
      
      return p.copyWith(
        isAlive: isAlive,
        isSilenced: isSilenced,
      );
    }).toList();

    // 8. Create resolution event
    final resolutionEvent = GameEvent(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      gameId: state.id,
      round: state.round,
      phase: Phase.nightResolution,
      type: EventType.nightResolutionSummary,
      timestamp: DateTime.now(),
      metadata: {
        'assassinatedIds': deadPlayerIds.toList(),
        'protectedIds': protectedTargetIds.toList(),
        'silencedIds': silencedPlayerIds.toList(),
        'successfulProtections': finalAssassinationTargets.where((t) => protectedTargetIds.contains(t)).toList(),
      },
    );"""


new_logic = """    // 5. Calculate deaths
    final mafiaDeadIds = <String>{};
    final sniperDeadIds = <String>{};
    final protectedFromMafiaIds = <String>{};
    final protectedFromSniperIds = <String>{};

    // Separate mafia targets and sniper targets
    final mafiaTargets = assassinations.map((e) => e.targetId!).toSet();
    final sniperTargets = sniperKills.map((e) => e.targetId!).toSet();

    for (var targetId in mafiaTargets) {
      if (protectedTargetIds.contains(targetId)) {
        protectedFromMafiaIds.add(targetId);
      } else {
        mafiaDeadIds.add(targetId);
      }
    }

    for (var targetId in sniperTargets) {
      if (protectedTargetIds.contains(targetId)) {
        protectedFromSniperIds.add(targetId);
      } else {
        sniperDeadIds.add(targetId);
      }
    }

    final deadPlayerIds = {...mafiaDeadIds, ...sniperDeadIds};

    // 6. Calculate silences
    final silencedPlayerIds = silences.map((e) => e.targetId!).toSet();

    // 7. Update players
    final updatedPlayers = state.players.map((p) {
      bool isAlive = p.isAlive;
      bool isSilenced = silencedPlayerIds.contains(p.id);

      if (deadPlayerIds.contains(p.id)) {
        isAlive = false;
      }

      if (!isAlive) {
        isSilenced = false;
      }

      return p.copyWith(
        isAlive: isAlive,
        isSilenced: isSilenced,
      );
    }).toList();

    // 8. Create resolution event
    final resolutionEvent = GameEvent(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      gameId: state.id,
      round: state.round,
      phase: Phase.nightResolution,
      type: EventType.nightResolutionSummary,
      timestamp: DateTime.now(),
      metadata: {
        'assassinatedIds': deadPlayerIds.toList(),
        'mafiaDeadIds': mafiaDeadIds.toList(),
        'sniperDeadIds': sniperDeadIds.toList(),
        'protectedIds': protectedTargetIds.toList(),
        'silencedIds': silencedPlayerIds.toList(),
        'protectedFromMafiaIds': protectedFromMafiaIds.toList(),
        'protectedFromSniperIds': protectedFromSniperIds.toList(),
      },
    );"""

content = content.replace(old_logic, new_logic)

with open('lib/domain/engine/night_resolution_engine.dart', 'w') as f:
    f.write(content)
