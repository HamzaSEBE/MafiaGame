import re

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'r') as f:
    content = f.read()

old_mapping = """          final type = switch (action.actionType) {
            'assassination' => EventType.assassination,
            'protection' => EventType.protection,
            'investigation' => EventType.investigation,
            'silence' => EventType.silence,
            _ => null,
          };"""

new_mapping = """          final type = switch (action.actionType) {
            'assassination' => EventType.assassination,
            'protection' => EventType.protection,
            'investigation' => EventType.investigation,
            'silence' => EventType.silence,
            'sniperKill' => EventType.sniperKill,
            'sleep' => null,
            _ => null,
          };"""

content = content.replace(old_mapping, new_mapping)

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'w') as f:
    f.write(content)
