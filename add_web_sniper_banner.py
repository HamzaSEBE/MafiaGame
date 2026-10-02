import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

old_code = """                    if (_isShowingRole && role != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppTheme.roleAbilityDescription(role),"""

new_code = """                    if (_isShowingRole && role != null) ...[
                      const SizedBox(height: 8),
                      if (secret.isSniper) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amberAccent),
                          ),
                          child: const Text(
                            'لديك قدرة القنص لمرة واحدة ليلاً!',
                            style: TextStyle(fontSize: 14, color: Colors.amberAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        AppTheme.roleAbilityDescription(role),"""

content = content.replace(old_code, new_code)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
