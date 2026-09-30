import re

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'r') as f:
    content = f.read()

old_listen = """    _actionsSubscription =
        service.streamActionRequests(widget.sessionId).listen(
      (actions) {
        _liveActions = actions;
        _publishAvailableInvestigationResults();
      },
      onError: (_) {},
    );
  }"""

new_listen = """    _actionsSubscription =
        service.streamActionRequests(widget.sessionId).listen(
      (actions) {
        _liveActions = actions;
        _processInstantActions(actions);
        _publishAvailableInvestigationResults();
      },
      onError: (_) {},
    );
  }

  void _processInstantActions(List<ActionRequest> actions) {
    if (!mounted || _liveSession == null) return;
    final state = ref.read(gameOrchestratorProvider);
    final service = ref.read(interactiveServiceProvider);

    for (final action in actions) {
      if (action.actionType == 'citizenSheikhReveal') {
        final seat = _seatForUid(_liveSeats, action.uid);
        if (seat != null) {
          final player = state.getPlayerById(seat.id);
          if (player != null && player.role == Role.citizensSheikh && !player.isCitizenSheikhRevealed) {
            ref.read(gameOrchestratorProvider.notifier).citizenSheikhReveal(seat.id);
            _syncState();
            service.clearActionRequest(widget.sessionId, action.id);
          }
        }
      }
    }
  }"""

content = content.replace(old_listen, new_listen)

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'w') as f:
    f.write(content)
