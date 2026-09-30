import re

with open('lib/presentation/game_over/game_over_screen.dart', 'r') as f:
    content = f.read()

old_header = """                  const SizedBox(height: 16),
                  Text(
                    'انتصار $winnerStr',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: winnerColor,
                      fontFamily: 'Cairo',
                      shadows: [Shadow(color: winnerColor.withValues(alpha: 0.5), blurRadius: 20)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),"""

new_header = """                  const SizedBox(height: 16),
                  Text(
                    'انتصار $winnerStr',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: winnerColor,
                      fontFamily: 'Cairo',
                      shadows: [Shadow(color: winnerColor.withValues(alpha: 0.5), blurRadius: 20)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.victoryReason != null)
                    Text(
                      'السبب: ${state.victoryReason}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),"""

content = content.replace(old_header, new_header)

with open('lib/presentation/game_over/game_over_screen.dart', 'w') as f:
    f.write(content)
