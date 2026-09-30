import re

with open('lib/presentation/setup/setup_screen.dart', 'r') as f:
    content = f.read()

import_statement = "import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';"
new_import = "import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';\nimport 'package:mafia_nightfall/presentation/setup/rule_settings_screen.dart';"
content = content.replace(import_statement, new_import)

old_start_button = """                // Start Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedContainer("""

new_start_button = """                // Rule Settings Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings, color: Colors.orangeAccent),
                    label: const Text('قوانين وإعدادات اللعبة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.orangeAccent, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RuleSettingsScreen()));
                    },
                  ),
                ),
                
                // Start Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedContainer("""

content = content.replace(old_start_button, new_start_button)

with open('lib/presentation/setup/setup_screen.dart', 'w') as f:
    f.write(content)
