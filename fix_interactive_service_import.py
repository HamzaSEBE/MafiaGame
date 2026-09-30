import re

with open('lib/data/services/interactive/interactive_service.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:mafia_nightfall/domain/enums/phase.dart';", "import 'package:mafia_nightfall/domain/enums/phase.dart';\nimport 'package:mafia_nightfall/domain/events/game_event.dart';")

with open('lib/data/services/interactive/interactive_service.dart', 'w') as f:
    f.write(content)
