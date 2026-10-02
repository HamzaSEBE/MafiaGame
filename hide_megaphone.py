import re

def modify_screen(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # for DayScreen
    content = content.replace(
        "if (state.rules.abilityRules.citizenSheikhReveal)",
        "if (state.rules.abilityRules.citizenSheikhReveal && widget.interactiveSessionId == null)"
    )
    
    # for VotingScreen
    content = content.replace(
        "if (ref\n                .read(gameOrchestratorProvider)\n                .rules\n                .abilityRules\n                .citizenSheikhReveal)",
        "if (ref.read(gameOrchestratorProvider).rules.abilityRules.citizenSheikhReveal && widget.interactiveSessionId == null)"
    )
    content = content.replace(
        "if (ref.read(gameOrchestratorProvider).rules.abilityRules.citizenSheikhReveal)",
        "if (ref.read(gameOrchestratorProvider).rules.abilityRules.citizenSheikhReveal && widget.interactiveSessionId == null)"
    )

    with open(filepath, 'w') as f:
        f.write(content)

modify_screen('lib/presentation/day/day_screen.dart')
modify_screen('lib/presentation/voting/voting_screen.dart')
