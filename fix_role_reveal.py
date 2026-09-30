import re

with open('lib/presentation/reveal/role_reveal_screen.dart', 'r') as f:
    content = f.read()

old_reveal = """                    Text(
                      AppTheme.roleArabicName(_currentPlayer.role),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppTheme.roleAbilityDescription(_currentPlayer.role),
                        style: TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                    ),"""

new_reveal = """                    Text(
                      AppTheme.roleArabicName(_currentPlayer.role),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_currentPlayer.hasSniper) ...[
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppTheme.roleAbilityDescription(_currentPlayer.role),
                        style: TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                    ),"""

content = content.replace(old_reveal, new_reveal)

with open('lib/presentation/reveal/role_reveal_screen.dart', 'w') as f:
    f.write(content)
