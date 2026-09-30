import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Skip if already watches selectedThemeProvider (except themes_screen itself)
    if 'ref.watch(selectedThemeProvider)' in content and not 'themes_screen.dart' in filepath:
        return

    changed = False

    # Find the build method
    # Pattern: Widget build(BuildContext context) {
    # or: Widget build(BuildContext context, WidgetRef ref) {
    pattern = r'(Widget\s+build\(\s*BuildContext\s+context(?:,\s*WidgetRef\s+ref)?\s*\)\s*\{)'
    
    if re.search(pattern, content):
        # We need to make sure the file imports the provider
        import_stmt = "import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';"
        if import_stmt not in content:
            # Add import after the first import
            content = re.sub(r'^(import .*?;)', r'\1\n' + import_stmt, content, count=1, flags=re.MULTILINE)
        
        # Inject ref.watch
        replacement = r'\1\n    ref.watch(selectedThemeProvider);'
        content = re.sub(pattern, replacement, content)
        changed = True

    if changed:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib/presentation'):
    for file in files:
        if file.endswith('.dart') and 'themes_screen.dart' not in file:
            process_file(os.path.join(root, file))

