import re

with open('lib/presentation/home/home_screen.dart', 'r') as f:
    content = f.read()

pattern = r'(class _HomeScreenState extends ConsumerState<HomeScreen> \{.*?Widget build\(BuildContext context\) \{)'
replacement = r'\1\n    ref.watch(selectedThemeProvider);'

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/presentation/home/home_screen.dart', 'w') as f:
    f.write(content)
