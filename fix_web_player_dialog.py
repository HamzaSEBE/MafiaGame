import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

old_vars = """  bool _sessionEnded = false;
  Phase? _lastPhase;
  int? _lastActionRevision;"""

new_vars = """  bool _sessionEnded = false;
  Phase? _lastPhase;
  int? _lastActionRevision;
  String? _lastSeenAnnouncement;"""

content = content.replace(old_vars, new_vars)

old_init = """    _sessionSubscription = service.streamSession(widget.sessionId).listen(
      (session) {
        if (!mounted || session?.status != SessionStatus.finished) return;
        setState(() => _sessionEnded = true);
      },
    );"""

new_init = """    _sessionSubscription = service.streamSession(widget.sessionId).listen(
      (session) {
        if (!mounted) return;
        if (session?.status == SessionStatus.finished) {
          setState(() => _sessionEnded = true);
        }
        
        if (session?.globalAnnouncement != null && session?.globalAnnouncement != _lastSeenAnnouncement) {
          _lastSeenAnnouncement = session?.globalAnnouncement;
          
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
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppTheme.roleImage(Role.citizensSheikh),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(session!.globalAnnouncement!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center),
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
      },
    );"""

content = content.replace(old_init, new_init)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
