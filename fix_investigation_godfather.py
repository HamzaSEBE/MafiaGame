import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_logic = """    if (isMafia) {
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
    }"""

new_logic = """    if (isMafia) {
      if (target.role == Role.mafiaSheikh) {
        if (aRules.mafiaSheikhReveal) {
          resultText = 'من المافيا!';
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
    }"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
