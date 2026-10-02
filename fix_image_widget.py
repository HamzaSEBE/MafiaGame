import re

def fix_file(filename):
    with open(filename, 'r') as f:
        content = f.read()

    old_code = "child: AppTheme.roleImage(Role.citizensSheikh),"
    new_code = "child: Image.asset(AppTheme.roleImage(Role.citizensSheikh), fit: BoxFit.cover),"

    content = content.replace(old_code, new_code)

    with open(filename, 'w') as f:
        f.write(content)

fix_file('lib/presentation/day/day_screen.dart')
fix_file('lib/presentation/interactive/web/web_player_screen.dart')
