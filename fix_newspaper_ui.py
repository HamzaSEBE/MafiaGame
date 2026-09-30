import re

with open('lib/presentation/widgets/newspaper_widget.dart', 'r') as f:
    content = f.read()

old_conclusion = """    final String winnerStr;
    if (gameState.winner == Team.mafia) winnerStr = 'المافيا';
    else if (gameState.winner == Team.independent) winnerStr = 'المهرج (الجوكر)';
    else winnerStr = 'المواطنون';"""

new_conclusion = """    final String winnerStr;
    if (gameState.winner == Team.mafia) winnerStr = 'المافيا';
    else if (gameState.winner == Team.independent) winnerStr = 'المهرج (الجوكر)';
    else winnerStr = 'المواطنون';
    
    final reasonText = gameState.victoryReason != null ? 'السبب: ${gameState.victoryReason}' : '';"""

content = content.replace(old_conclusion, new_conclusion)

old_body = """            Text(
              'المنتصر: $winnerStr',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),"""

new_body = """            Text(
              'المنتصر: $winnerStr',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            if (reasonText.isNotEmpty)
              Text(
                reasonText,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),"""

content = content.replace(old_body, new_body)

with open('lib/presentation/widgets/newspaper_widget.dart', 'w') as f:
    f.write(content)
