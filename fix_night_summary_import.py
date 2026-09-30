import re

with open('lib/presentation/night/night_summary_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:mafia_nightfall/domain/entities/player.dart';", "import 'package:mafia_nightfall/domain/entities/player.dart';\nimport 'package:mafia_nightfall/domain/entities/game_state.dart';")

with open('lib/presentation/night/night_summary_screen.dart', 'w') as f:
    f.write(content)
