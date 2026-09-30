import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_result = """  void _showInvestigationResult(Player target) {
    final isMafia = target.role.team == Team.mafia;"""

new_result = """  void _showInvestigationResult(Player target) {
    final state = ref.read(gameOrchestratorProvider);
    final aRules = state.rules.abilityRules;
    
    bool isMafia = target.role.team == Team.mafia;
    bool isJoker = target.role == Role.joker;
    
    if (target.role == Role.mafiaSheikh && !aRules.mafiaSheikhReveal) {
      isMafia = false; // Hidden
    }
    
    String resultText = isMafia ? 'من المافيا!' : 'من المواطنين';
    Color resultColor = isMafia ? Colors.redAccent : Colors.greenAccent;
    IconData resultIcon = isMafia ? Icons.warning_rounded : Icons.check_circle_outline;
    
    if (isJoker && aRules.jokerReveal) {
      resultText = 'المهرج (الجوكر)!';
      resultColor = Colors.purpleAccent;
      resultIcon = Icons.theater_comedy;
    }"""

content = content.replace(old_result, new_result)

content = content.replace("color: isMafia ? Colors.redAccent : Colors.greenAccent", "color: resultColor")
content = content.replace("Icon(isMafia ? Icons.warning_rounded : Icons.check_circle_outline", "Icon(resultIcon")
content = content.replace("isMafia ? 'من المافيا!' : 'من المواطنين'", "resultText")

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
