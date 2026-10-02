import re

with open('lib/application/game_orchestrator.dart', 'r') as f:
    content = f.read()

old_code = """  void beginIntroductionNight() {
    if (state.phase != Phase.roleReveal) return;
    state = state.copyWith(phase: Phase.night, round: 1);
  }"""

new_code = """  void beginIntroductionNight() {
    if (state.phase != Phase.roleReveal) return;
    state = state.copyWith(phase: Phase.night, round: 1);
  }

  void skipIntroductionNight() {
    if (state.phase != Phase.roleReveal) return;
    state = state.copyWith(phase: Phase.day, round: 1);
  }"""

content = content.replace(old_code, new_code)

with open('lib/application/game_orchestrator.dart', 'w') as f:
    f.write(content)
