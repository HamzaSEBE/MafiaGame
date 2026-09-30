import re

with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Replace the block manually
old_block = """  static Color teamColor(Team team) {
    if (team == Team.mafia) return mafiaPrimary;
    if (team == Team.independent) return Colors.purpleAccent;
    return citizensPrimary;
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return citizensPrimary;
    return specialAction;
  }"""

new_block = """  static Color teamColor(Team team) {
    if (team == Team.mafia) return const Color(0xFF8B0000);
    if (team == Team.independent) return Colors.purpleAccent;
    return accent;
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000);
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return Colors.white;
    return accent;
  }"""

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('lib/presentation/theme/app_theme.dart', 'w') as f:
        f.write(content)
    print("Success")
else:
    print("Block not found!")
