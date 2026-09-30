import re

with open('lib/presentation/instructions/instructions_screen.dart', 'r') as f:
    content = f.read()

# Replace Mafia Nightfall
content = content.replace('مافيا نايت فول هي لعبة', 'مافيا عالشوارب هي لعبة')

# Replace Sheikh Mafia
content = content.replace(
    'زعيم المافيا المحصن. يشارك في القتل ليلاً، وإذا قام شيخ المواطنين بالتحقيق عنه، ستظهر هويته كـ "مواطن صالح" (لا يُكشف).',
    'زعيم المافيا القوي. يشارك في القتل ليلاً ويقود العصابة.'
)

with open('lib/presentation/instructions/instructions_screen.dart', 'w') as f:
    f.write(content)
