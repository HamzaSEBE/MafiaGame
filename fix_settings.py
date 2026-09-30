import re

with open('lib/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()

# Replace the simple isMafia logic with AppTheme.roleColor and AppTheme.roleIcon
new_logic = """
                    final color = AppTheme.roleColor(role);
                    final icon = AppTheme.roleIcon(role);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 32),
"""

# find "final isMafia"
content = re.sub(
    r"final isMafia =.*?;.*?return Container\(.*?decoration: BoxDecoration\(.*?border: Border\.all\(color: isMafia \? Colors\.redAccent\.withValues\(alpha: 0\.2\) : Colors\.blueAccent\.withValues\(alpha: 0\.2\)\),.*?child: Row\(.*?children: \[.*?Icon\(.*?isMafia \? Icons\.local_fire_department : Icons\.shield,.*?color: isMafia \? Colors\.redAccent : Colors\.blueAccent,.*?size: 32.*?\),",
    new_logic.strip(),
    content,
    flags=re.DOTALL
)

with open('lib/presentation/settings/settings_screen.dart', 'w') as f:
    f.write(content)
