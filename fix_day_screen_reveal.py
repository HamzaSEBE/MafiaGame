import re

with open('lib/presentation/day/day_screen.dart', 'r') as f:
    content = f.read()

old_build_start = """  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final state = ref.watch(gameOrchestratorProvider);"""

new_build_start = """  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final state = ref.watch(gameOrchestratorProvider);
    
    // Listen for Citizen Sheikh reveal event to show it to all clients/moderator
    ref.listen(gameOrchestratorProvider, (previous, next) {
      if (previous == null) return;
      final prevEvents = previous.eventHistory.length;
      final nextEvents = next.eventHistory.length;
      if (nextEvents > prevEvents) {
        final newEvent = next.eventHistory.last;
        if (newEvent.type == EventType.citizenSheikhReveal) {
          final sheikh = next.getPlayerById(newEvent.actorId!);
          if (sheikh != null) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.orangeAccent, width: 2)),
                title: const Column(
                  children: [
                    Icon(Icons.campaign, color: Colors.orangeAccent, size: 60),
                    SizedBox(height: 16),
                    Text('إفصاح شيخ المواطنين!', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('اللاعب ${sheikh.name}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    const Text('كشف عن نفسه كشيخ للمواطنين!', style: TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('أصبح صوته الآن يعادل 3 أصوات!', style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                    )
                  ],
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                      child: const Text('حسناً', style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        }
      }
    });"""

content = content.replace(old_build_start, new_build_start)

with open('lib/presentation/day/day_screen.dart', 'w') as f:
    f.write(content)
