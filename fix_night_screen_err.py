import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_code = """    String resultText = resultText;
    Color resultColor = isMafia ? Colors.redAccent : Colors.greenAccent;
    IconData resultIcon = isMafia ? Icons.warning_rounded : Icons.check_circle_outline;"""

new_code = """    String resultText = isMafia ? 'من المافيا!' : 'من المواطنين';
    Color resultColor = isMafia ? Colors.redAccent : Colors.greenAccent;
    IconData resultIcon = isMafia ? Icons.warning_rounded : Icons.check_circle_outline;"""

content = content.replace(old_code, new_code)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
