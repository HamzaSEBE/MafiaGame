import re

def fix_file(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # The buggy code is:
    # ref.read(gameOrchestratorProvider.notifier).citizenSheikhReveal(sheikh.id);
    # Navigator.pop(ctx);
    # We will swap them.
    # Note that in voting_screen.dart it might be multiline due to dart format.
    
    # We'll use a regex to capture it carefully.
    pattern = r'(ref\s*\.read\(gameOrchestratorProvider\.notifier\)\s*\.citizenSheikhReveal\(sheikh\.id\);)\s*(Navigator\.pop\(ctx\);)'
    
    new_content = re.sub(pattern, r'\2\n                            \1', content)
    
    with open(filename, 'w') as f:
        f.write(new_content)

fix_file('lib/presentation/day/day_screen.dart')
fix_file('lib/presentation/voting/voting_screen.dart')
