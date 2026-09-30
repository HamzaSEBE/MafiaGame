import re

with open('lib/presentation/night/night_summary_screen.dart', 'r') as f:
    content = f.read()

# I will replace the build method completely
# First find the start of `Widget build(BuildContext context)` and end of it.

def find_build_method():
    match = re.search(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}', content, re.DOTALL)
    if match:
        return match.group(0)
    
    match2 = re.search(r'  @override\n  Widget build\(BuildContext context\) \{.*', content, re.DOTALL)
    if match2:
        return match2.group(0)
    return None

old_build = find_build_method()

new_build = """  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final state = ref.watch(gameOrchestratorProvider);

    final summaryEvent = state.eventHistory
        .where((e) => e.type == EventType.nightResolutionSummary)
        .lastOrNull;

    final mafiaDeadIds = (summaryEvent?.metadata['mafiaDeadIds'] as List?)?.cast<String>() ?? [];
    final sniperDeadIds = (summaryEvent?.metadata['sniperDeadIds'] as List?)?.cast<String>() ?? [];
    final silencedIds = (summaryEvent?.metadata['silencedIds'] as List?)?.cast<String>() ?? [];
    
    final protectedFromMafiaIds = (summaryEvent?.metadata['protectedFromMafiaIds'] as List?)?.cast<String>() ?? [];
    final protectedFromSniperIds = (summaryEvent?.metadata['protectedFromSniperIds'] as List?)?.cast<String>() ?? [];
    
    final assassinatedIds = [...mafiaDeadIds, ...sniperDeadIds];

    String getNames(List<String> ids) {
      if (ids.isEmpty) return 'لا أحد';
      return ids
          .map((id) => state.getPlayerById(id)?.name ?? 'مجهول')
          .join('، ');
    }

    return GamePopScope(
      onExit: widget.onInteractiveExit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملخص الليل (للحكم فقط)',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
                child: Container(
                    decoration: const BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [Color(0xFF151826), Color(0xFF07070B)])))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.wb_twilight,
                        size: 80, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'انتهى الليل، وإليك ما حدث في العتمة:',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            if (protectedFromMafiaIds.isNotEmpty)
                              ...protectedFromMafiaIds.map((id) {
                                final player = state.getPlayerById(id);
                                return _buildProtectionCard('حمت ${player?.name ?? ''} من اغتيال المافيا!', Colors.greenAccent);
                              }),
                            if (protectedFromSniperIds.isNotEmpty)
                              ...protectedFromSniperIds.map((id) {
                                final player = state.getPlayerById(id);
                                return _buildProtectionCard('حمت ${player?.name ?? ''} من قنص القناص!', Colors.tealAccent);
                              }),
                            if (mafiaDeadIds.isNotEmpty)
                              ...mafiaDeadIds.map((id) {
                                return _buildDeathCard(state, id, 'ضحية الليل (تم اغتياله):', Colors.redAccent);
                              }),
                            if (sniperDeadIds.isNotEmpty)
                              ...sniperDeadIds.map((id) {
                                return _buildDeathCard(state, id, 'ضحية الليل (تم قنصه):', Colors.orangeAccent);
                              }),
                            if (silencedIds.isNotEmpty)
                              _SummaryCard(
                                title: 'تم إسكاتهم (لا يحق لهم الكلام):',
                                names: getNames(silencedIds),
                                icon: Icons.volume_off,
                                color: Colors.blueAccent,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.interactiveSessionId != null &&
                              state.phase == Phase.triggeredAbility) {
                            Navigator.of(context).pop();
                          } else if (state.phase == Phase.triggeredAbility &&
                              assassinatedIds.isNotEmpty) {
                            _showCitizenBoyDialog(assassinatedIds.first);
                          } else {
                            _goToDay();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.phase == Phase.triggeredAbility
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.phase == Phase.triggeredAbility
                                  ? 'رد فعل المواطن الشجاع!'
                                  : 'متابعة',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo'),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}"""

content = content.replace(old_build, new_build)

with open('lib/presentation/night/night_summary_screen.dart', 'w') as f:
    f.write(content)
