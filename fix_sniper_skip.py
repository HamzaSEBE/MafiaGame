import re

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'r') as f:
    content = f.read()

old_logic = """          if (type == null) continue;
          orchestrator.submitNightAction(
            actorId: seat.id,
            targetId: action.targetId,
            type: type,
          );"""

new_logic = """          if (type == null) continue;
          
          if (type == EventType.sniperKill && action.targetId == seat.id) {
            // Sniper chose himself to skip. Do not record the shot so he can use it later.
            continue; 
          }
          
          orchestrator.submitNightAction(
            actorId: seat.id,
            targetId: action.targetId,
            type: type,
          );"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'w') as f:
    f.write(content)
