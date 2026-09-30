import re

with open('lib/presentation/premium/pricing_screen.dart', 'r') as f:
    content = f.read()

# Replace hardcoded Colors.blueAccent and Gold with AppTheme dynamic colors
content = content.replace("Colors.blueAccent,", "AppTheme.iconColor3,")
content = content.replace("const Color(0xFFFFD700)", "AppTheme.accent")
content = content.replace("Color(0xFFFFD700)", "AppTheme.accent")
content = content.replace("color: Colors.blueAccent", "color: AppTheme.iconColor3")

with open('lib/presentation/premium/pricing_screen.dart', 'w') as f:
    f.write(content)
