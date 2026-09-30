import re

with open('lib/presentation/reveal/role_reveal_screen.dart', 'r') as f:
    content = f.read()

# Replace hardcoded orange accents with theme glowColor/accent
content = content.replace("Colors.orangeAccent", "AppTheme.glowColor")
content = content.replace("Colors.redAccent.withValues(alpha: 0.5)", "AppTheme.glowColor.withValues(alpha: 0.5)")
content = content.replace("Colors.red.shade900", "AppTheme.background")

# Replace the ternary operators that expose the role!
pattern = r"\(_currentPlayer\.role\.name\.toLowerCase\(\)\.contains\('mafia'\)\)\s*\?\s*Colors\.redAccent(?:.*?)\s*:\s*Colors\.blueAccent(?:.*?),"
content = re.sub(pattern, "AppTheme.glowColor,", content)

pattern_with_values = r"\(_currentPlayer\.role\.name\.toLowerCase\(\)\.contains\('mafia'\)\)\s*\?\s*Colors\.redAccent\.withValues\(alpha:\s*(0\.\d+)\)\s*:\s*Colors\.blueAccent\.withValues\(alpha:\s*(0\.\d+)\)"
content = re.sub(pattern_with_values, r"AppTheme.glowColor.withValues(alpha: \1)", content)

with open('lib/presentation/reveal/role_reveal_screen.dart', 'w') as f:
    f.write(content)
