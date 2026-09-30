import re

with open('lib/presentation/widgets/judge_tools_sheet.dart', 'r') as f:
    content = f.read()

old_switch = """          case EventType.nightResolutionSummary:
            desc = 'نهاية جولة ${e.round}';
            icon = Icons.nights_stay;
            color = Colors.indigoAccent;
            break;
        }"""

new_switch = """          case EventType.nightResolutionSummary:
            desc = 'نهاية جولة ${e.round}';
            icon = Icons.nights_stay;
            color = Colors.indigoAccent;
            break;
          case EventType.sniperKill:
            desc = 'القناص اغتال ${target?.name ?? "شخصاً"}';
            icon = Icons.my_location;
            color = Colors.amberAccent;
            break;
          case EventType.citizenSheikhReveal:
            desc = 'أفصح شيخ المواطنين عن نفسه';
            icon = Icons.campaign;
            color = Colors.orangeAccent;
            break;
        }"""

content = content.replace(old_switch, new_switch)

with open('lib/presentation/widgets/judge_tools_sheet.dart', 'w') as f:
    f.write(content)
