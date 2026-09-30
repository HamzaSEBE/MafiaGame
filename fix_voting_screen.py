import re

with open('lib/presentation/voting/voting_screen.dart', 'r') as f:
    content = f.read()

# Only inject in class _VotingScreenState
pattern = r'(class _VotingScreenState extends ConsumerState<VotingScreen> \{.*?Widget build\(BuildContext context\) \{)'
replacement = r'\1\n    ref.watch(selectedThemeProvider);'

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/presentation/voting/voting_screen.dart', 'w') as f:
    f.write(content)
