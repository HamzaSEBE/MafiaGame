import re

with open('lib/presentation/day/day_screen.dart', 'r') as f:
    content = f.read()

old_judge_tools = """            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              tooltip: 'إنهاء اللعبة',
              onPressed: () => _confirmExit(context, ref),
            ),"""

new_judge_tools = """            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
            if (state.rules.abilityRules.citizenSheikhReveal)
              IconButton(
                icon: const Icon(Icons.campaign, color: Colors.orangeAccent),
                tooltip: 'إفصاح شيخ المواطنين',
                onPressed: () {
                  final sheikh = state.alivePlayers.where((p) => p.role == Role.citizensSheikh && !p.isCitizenSheikhRevealed).firstOrNull;
                  if (sheikh == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('لا يمكن الكشف: شيخ المواطنين ميت أو كشف عن نفسه مسبقاً', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.redAccent,
                    ));
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E24),
                      title: const Text('إفصاح شيخ المواطنين', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                      content: Text('هل أنت متأكد من أن ${sheikh.name} يريد الكشف عن هويته؟ سيصبح صوته بـ 3 أصوات لآخر اللعبة.', style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'))),
                        TextButton(
                          onPressed: () {
                            ref.read(gameOrchestratorProvider.notifier).citizenSheikhReveal(sheikh.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text('تأكيد الكشف', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              tooltip: 'إنهاء اللعبة',
              onPressed: () => _confirmExit(context, ref),
            ),"""

content = content.replace(old_judge_tools, new_judge_tools)

with open('lib/presentation/day/day_screen.dart', 'w') as f:
    f.write(content)
