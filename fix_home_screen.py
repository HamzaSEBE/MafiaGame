import re

with open('lib/presentation/home/home_screen.dart', 'r') as f:
    content = f.read()

# Replace Interactive QR Red Gradient
content = content.replace("colors: [Color(0xFF8B0000), Color(0xFF4A0000)],", "colors: [AppTheme.primaryCardStart, AppTheme.primaryCardEnd],")

# Replace Interactive QR Icon Color
content = content.replace("color: Colors.redAccent.withValues(alpha: 0.2)", "color: AppTheme.borderHighlight.withValues(alpha: 0.2)")
content = content.replace("color: Colors.redAccent,", "color: AppTheme.borderHighlight,")
content = content.replace("BoxShadow(color: Colors.redAccent", "BoxShadow(color: AppTheme.glowColor")
content = content.replace("Shadow(color: Colors.redAccent", "Shadow(color: AppTheme.glowColor")

# Replace Offline card
content = content.replace("color: Colors.redAccent.withValues(alpha: 0.3)", "color: AppTheme.borderHighlight.withValues(alpha: 0.3)")

# Replace Teaser card (purple)
content = content.replace("colors: [\n                                  Colors.purpleAccent.withValues(alpha: 0.2),\n                                  Colors.deepPurple.withValues(alpha: 0.05),\n                                ],", "colors: [\n                                  AppTheme.secondaryCardStart.withValues(alpha: 0.2),\n                                  AppTheme.secondaryCardEnd.withValues(alpha: 0.05),\n                                ],")
content = content.replace("color: Colors.purpleAccent.withValues(alpha: 0.3)", "color: AppTheme.secondaryCardStart.withValues(alpha: 0.3)")
content = content.replace("color: Colors.purpleAccent,", "color: AppTheme.secondaryCardStart,")

# Replace Action Grid Icons
content = content.replace("Colors.redAccent", "AppTheme.iconColor1")
content = content.replace("Colors.amber", "AppTheme.iconColor2")
content = content.replace("Colors.blueAccent", "AppTheme.iconColor3")

with open('lib/presentation/home/home_screen.dart', 'w') as f:
    f.write(content)
