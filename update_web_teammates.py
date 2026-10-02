import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

old_code = """                      const SizedBox(height: 4),
                      Text(
                        AppTheme.roleAbilityDescription(role),"""

new_code = """                      if (secret.mafiaTeammates.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'زملاؤك في المافيا:\n${secret.mafiaTeammates.join("، ")}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        AppTheme.roleAbilityDescription(role),"""

content = content.replace(old_code, new_code)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
