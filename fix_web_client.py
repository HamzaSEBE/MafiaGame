import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

# Add global announcement dialog or banner
old_scaffold_start = """    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      appBar: AppBar("""

new_scaffold_start = """    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      appBar: AppBar("""

# Let's show globalAnnouncement using a listener or just a Banner?
# Instead of Banner, let's just use ref.listen on `sessionStreamProvider`.
# Actually, it's easier to just show it in the UI if `session.globalAnnouncement != null` and we haven't seen it.
old_build_start = """  @override
  Widget build(BuildContext context) {
    final mySeatAsync = ref.watch(mySeatStreamProvider(widget.sessionId));
    final mySecretAsync = ref.watch(mySecretStreamProvider(widget.sessionId));
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));
    final seatsAsync = ref.watch(seatsStreamProvider(widget.sessionId));"""

new_build_start = """  String? _lastSeenAnnouncement;

  @override
  Widget build(BuildContext context) {
    final mySeatAsync = ref.watch(mySeatStreamProvider(widget.sessionId));
    final mySecretAsync = ref.watch(mySecretStreamProvider(widget.sessionId));
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));
    final seatsAsync = ref.watch(seatsStreamProvider(widget.sessionId));
    
    ref.listen(sessionStreamProvider(widget.sessionId), (previous, next) {
      if (next.value?.globalAnnouncement != null && next.value?.globalAnnouncement != _lastSeenAnnouncement) {
        _lastSeenAnnouncement = next.value?.globalAnnouncement;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.orangeAccent, width: 2)),
            title: const Icon(Icons.campaign, color: Colors.orangeAccent, size: 60),
            content: Text(_lastSeenAnnouncement!, style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
    });"""

content = content.replace(old_build_start, new_build_start)

# Update the target lists to show x3 badge
old_radio_title = """                                  title: Text(
                                    target.playerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),"""

new_radio_title = """                                  title: Row(
                                    children: [
                                      Text(
                                        target.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      if (target.isCitizenSheikhRevealed) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(8)),
                                          child: const Text('x3', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      ]
                                    ],
                                  ),"""

content = content.replace(old_radio_title, new_radio_title)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
