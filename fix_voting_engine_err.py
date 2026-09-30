import re

with open('lib/domain/engine/voting_engine.dart', 'r') as f:
    content = f.read()

import_statement = "import 'package:mafia_nightfall/domain/enums/team.dart';"
new_import = "import 'package:mafia_nightfall/domain/enums/team.dart';\nimport 'package:mafia_nightfall/domain/enums/role.dart';"
content = content.replace(import_statement, new_import)

with open('lib/domain/engine/voting_engine.dart', 'w') as f:
    f.write(content)
