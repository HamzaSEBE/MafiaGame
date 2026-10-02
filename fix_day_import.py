import re

with open('lib/presentation/day/day_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mafia_nightfall/presentation/theme/app_theme.dart';")

with open('lib/presentation/day/day_screen.dart', 'w') as f:
    f.write(content)
