import re

with open('lib/data/services/interactive/interactive_service.dart', 'r') as f:
    content = f.read()

# Update updateSessionState
old_session_update = """    batch.update(sessionRef, {
      'status': (state.phase == Phase.winCheck
              ? SessionStatus.finished
              : SessionStatus.active)
          .name,
      'phase': state.phase.name,
      'round': state.round,
      'actionRevision': actionRevision,
      'actionsPhase': hasActionPrompts ? state.phase.name : null,
      'actionsRound': hasActionPrompts ? state.round : null,
      'winner': state.winner?.name,
    });"""

new_session_update = """    String? globalAnnouncement;
    if (state.eventHistory.isNotEmpty && state.eventHistory.last.type == EventType.citizenSheikhReveal) {
      final sheikhName = state.getPlayerById(state.eventHistory.last.actorId ?? '')?.name ?? 'شيخ المواطنين';
      globalAnnouncement = 'إفصاح شيخ المواطنين! اللاعب $sheikhName كشف عن نفسه! أصبح صوته الآن بـ 3 أصوات.';
    }

    batch.update(sessionRef, {
      'status': (state.phase == Phase.winCheck
              ? SessionStatus.finished
              : SessionStatus.active)
          .name,
      'phase': state.phase.name,
      'round': state.round,
      'actionRevision': actionRevision,
      'actionsPhase': hasActionPrompts ? state.phase.name : null,
      'actionsRound': hasActionPrompts ? state.round : null,
      'winner': state.winner?.name,
      if (globalAnnouncement != null) 'globalAnnouncement': globalAnnouncement,
    });"""

content = content.replace(old_session_update, new_session_update)

old_seat_update = """      batch.update(seatRef, {
        'isAlive': player.isAlive,
      });"""

new_seat_update = """      batch.update(seatRef, {
        'isAlive': player.isAlive,
        'isCitizenSheikhRevealed': player.isCitizenSheikhRevealed,
      });"""

content = content.replace(old_seat_update, new_seat_update)

with open('lib/data/services/interactive/interactive_service.dart', 'w') as f:
    f.write(content)
