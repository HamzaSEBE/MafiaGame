import re

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'r') as f:
    content = f.read()

old_button = """                    if (state.phase == Phase.roleReveal)
                      _phaseButton(
                        label: 'انتهى كشف الأدوار — ابدأ ليلة التعارف',
                        onPressed: _beginIntroductionNight,
                      ),"""

new_button = """                    if (state.phase == Phase.roleReveal)
                      _phaseButton(
                        label: 'انتهى كشف الأدوار — ابدأ النهار الأول',
                        onPressed: _skipIntroductionNight,
                      ),"""

content = content.replace(old_button, new_button)

old_method = """  Future<void> _beginIntroductionNight() => _runHostAction(() async {
        final service = ref.read(interactiveServiceProvider);
        await service.clearActionRequests(widget.sessionId);
        ref.read(gameOrchestratorProvider.notifier).beginIntroductionNight();
        await _syncStateToClients(clearPrivateResults: true);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NightScreen(
              interactiveSessionId: widget.sessionId,
              onInteractiveExit: _confirmEndSession,
            ),
          ),
        );
      });"""

new_method = """  Future<void> _skipIntroductionNight() => _runHostAction(() async {
        final service = ref.read(interactiveServiceProvider);
        await service.clearActionRequests(widget.sessionId);
        ref.read(gameOrchestratorProvider.notifier).skipIntroductionNight();
        await _syncStateToClients(clearPrivateResults: true);
        if (!mounted) return;
        await _openDayDiscussion();
      });"""

content = content.replace(old_method, new_method)

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'w') as f:
    f.write(content)
