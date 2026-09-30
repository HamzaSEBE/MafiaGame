with open('lib/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()
if "import 'package:mafia_nightfall/presentation/theme/app_theme.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mafia_nightfall/presentation/theme/app_theme.dart';")
with open('lib/presentation/settings/settings_screen.dart', 'w') as f:
    f.write(content)

with open('lib/presentation/premium/pricing_screen.dart', 'r') as f:
    content = f.read()
if "import 'package:mafia_nightfall/presentation/theme/app_theme.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mafia_nightfall/presentation/theme/app_theme.dart';")
# Remove const from Icon using AppTheme
content = content.replace("const Icon(Icons.workspace_premium, size: 80, color: AppTheme.accent)", "Icon(Icons.workspace_premium, size: 80, color: AppTheme.accent)")
with open('lib/presentation/premium/pricing_screen.dart', 'w') as f:
    f.write(content)
