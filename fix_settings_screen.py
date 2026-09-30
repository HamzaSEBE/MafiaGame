import re

with open('lib/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("Colors.blueAccent", "AppTheme.iconColor3")
content = content.replace("Colors.purpleAccent", "AppTheme.iconColor1")
content = content.replace("Colors.greenAccent", "AppTheme.iconColor2")

with open('lib/presentation/settings/settings_screen.dart', 'w') as f:
    f.write(content)
