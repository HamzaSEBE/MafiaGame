import re

with open('lib/presentation/widgets/game_pop_scope.dart', 'r') as f:
    content = f.read()

import_statement = "import 'package:flutter/material.dart';"
new_import = "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mafia_nightfall/application/game_orchestrator.dart';"
content = content.replace(import_statement, new_import)

old_class = "class GamePopScope extends StatelessWidget {"
new_class = "class GamePopScope extends ConsumerWidget {"
content = content.replace(old_class, new_class)

old_build = "  Widget build(BuildContext context) {"
new_build = "  Widget build(BuildContext context, WidgetRef ref) {"
content = content.replace(old_build, new_build)

old_exit = """        if (exit == true && context.mounted) {
          if (onExit != null) {
            await onExit!();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }"""

new_exit = """        if (exit == true && context.mounted) {
          ref.read(gameOrchestratorProvider.notifier).resetGame();
          if (onExit != null) {
            await onExit!();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }"""

content = content.replace(old_exit, new_exit)

with open('lib/presentation/widgets/game_pop_scope.dart', 'w') as f:
    f.write(content)
