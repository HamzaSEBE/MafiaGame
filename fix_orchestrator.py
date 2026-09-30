import re

with open('lib/application/game_orchestrator.dart', 'r') as f:
    content = f.read()

# Replace _ruleset field
content = re.sub(r'final GameRuleset _ruleset = const GameRuleset\(\);', '', content)

# Replace usage of _ruleset
content = content.replace("NightResolutionEngine.resolve(state, _ruleset);", "NightResolutionEngine.resolve(state, state.rules);")

old_assignRoles = """  /// Shuffle and assign roles based on [roleConfig] (Map<Role, count>).
  /// Returns an error string if the total doesn't match player count, else null.
  String? assignRoles(Map<Role, int> roleConfig) {"""

new_assignRoles = """  void updateRules(GameRuleset rules) {
    state = state.copyWith(rules: rules);
  }

  void citizenSheikhReveal(String playerId) {
    final players = state.players.map((p) {
      if (p.id == playerId && p.role == Role.citizensSheikh) {
        return p.copyWith(isCitizenSheikhRevealed: true);
      }
      return p;
    }).toList();
    
    final event = GameEvent(
      id: const Uuid().v4(),
      gameId: state.id,
      round: state.round,
      phase: state.phase,
      type: EventType.citizenSheikhReveal,
      actorId: playerId,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      players: players,
      eventHistory: [...state.eventHistory, event]
    );
  }

  /// Shuffle and assign roles based on [roleConfig] (Map<Role, count>).
  /// Returns an error string if the total doesn't match player count, else null.
  String? assignRoles(Map<Role, int> roleConfig) {"""

content = content.replace(old_assignRoles, new_assignRoles)

old_assign_end = """    state = state.copyWith(
      players: updatedPlayers,
      phase: Phase.roleReveal,
    );
    return null; // success
  }"""

new_assign_end = """    // Calculate initial Mafia Count
    final initialMafiaCount = updatedPlayers.where((p) => p.role.team == Team.mafia).length;

    // Assign Sniper if rule is enabled
    if (state.rules.abilityRules.sniper) {
      final citizens = updatedPlayers.where((p) => p.role.team == Team.citizens).toList();
      if (citizens.isNotEmpty) {
        citizens.shuffle(Random.secure());
        final sniperId = citizens.first.id;
        for (int i = 0; i < updatedPlayers.length; i++) {
          if (updatedPlayers[i].id == sniperId) {
            updatedPlayers[i] = updatedPlayers[i].copyWith(hasSniper: true);
          }
        }
      }
    }

    state = state.copyWith(
      players: updatedPlayers,
      phase: Phase.roleReveal,
      initialMafiaCount: initialMafiaCount,
    );
    return null; // success
  }"""

content = content.replace(old_assign_end, new_assign_end)

with open('lib/application/game_orchestrator.dart', 'w') as f:
    f.write(content)
