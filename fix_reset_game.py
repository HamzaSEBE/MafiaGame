import re

with open('lib/application/game_orchestrator.dart', 'r') as f:
    content = f.read()

old_reset = """  void resetGame() {
    state = GameState(id: const Uuid().v4());
  }"""

new_reset = """  void resetGame() {
    final cleanPlayers = state.players.map((p) => p.copyWith(
      role: Role.goodCitizen,
      isAlive: true,
      isSilenced: false,
      hasSniper: false,
      isCitizenSheikhRevealed: false,
    )).toList();
    state = GameState(id: const Uuid().v4(), players: cleanPlayers, rules: state.rules);
  }"""

content = content.replace(old_reset, new_reset)

with open('lib/application/game_orchestrator.dart', 'w') as f:
    f.write(content)
