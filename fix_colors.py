import re

with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Replace teamColor
content = content.replace("""  static Color teamColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000);
    if (role.team == Team.independent) return Colors.purpleAccent;
    return accent;
  }""", """  static Color teamColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000);
    if (role.team == Team.independent) return Colors.purpleAccent;
    return citizensPrimary;
  }""")

# Replace roleColor
content = content.replace("""  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000);
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return Colors.white;
    return accent;
  }""", """  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000);
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return Colors.white;
    return citizensPrimary;
  }""")

with open('lib/presentation/theme/app_theme.dart', 'w') as f:
    f.write(content)
