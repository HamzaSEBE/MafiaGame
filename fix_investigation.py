import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_logic = """    bool isMafia = target.role.team == Team.mafia;
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

new_logic = """    bool isMafia = target.role.team == Team.mafia;
    bool isJoker = target.role == Role.joker;
    
    String resultText = 'من المواطنين';
    Color resultColor = Colors.greenAccent;
    IconData resultIcon = Icons.check_circle_outline;

    if (isMafia) {
      if (target.role == Role.mafiaSheikh) {
        if (aRules.mafiaSheikhReveal) {
          resultText = 'شيخ المافيا!';
          resultColor = Colors.redAccent;
          resultIcon = Icons.warning_rounded;
        } else {
          // Hidden as citizen
          resultText = 'من المواطنين';
          resultColor = Colors.greenAccent;
          resultIcon = Icons.check_circle_outline;
        }
      } else {
        resultText = 'من المافيا!';
        resultColor = Colors.redAccent;
        resultIcon = Icons.warning_rounded;
      }
    } else if (isJoker && aRules.jokerReveal) {
      resultText = 'المهرج (الجوكر)!';
      resultColor = Colors.purpleAccent;
      resultIcon = Icons.theater_comedy;
    }"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
