with open('lib/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "import 'package:mafia_nightfall/application/premium_service.dart';",
    "import 'package:mafia_nightfall/application/premium_service.dart';\nimport 'package:mafia_nightfall/presentation/premium/themes_screen.dart';"
)

content = content.replace(
    """                // Navigate to Themes Screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('شاشة الثيمات قيد التطوير!', style: TextStyle(fontFamily: 'Cairo'))),
                );""",
    "Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemesScreen()));"
)

with open('lib/presentation/settings/settings_screen.dart', 'w') as f:
    f.write(content)
