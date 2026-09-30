import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    changed = False
    new_lines = []
    for line in lines:
        if 'AppTheme.' in line and 'const ' in line:
            # We want to remove 'const ' from this line.
            # But wait, it might be `const Text(...)` and inside it `color: AppTheme.xyz`.
            # We can just remove `const ` safely from the line.
            line = re.sub(r'\bconst\s+', '', line)
            changed = True
        new_lines.append(line)
        
    if changed:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)

for root, _, files in os.walk('lib/presentation'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

