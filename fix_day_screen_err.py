import re

with open('lib/presentation/day/day_screen.dart', 'r') as f:
    content = f.read()

import_statement = "import 'package:mafia_nightfall/domain/enums/phase.dart';"
new_import = "import 'package:mafia_nightfall/domain/enums/phase.dart';\nimport 'package:mafia_nightfall/domain/enums/role.dart';"
content = content.replace(import_statement, new_import)

with open('lib/presentation/day/day_screen.dart', 'w') as f:
    f.write(content)
