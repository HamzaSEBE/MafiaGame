import re

with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# I will replace the definitions of teamColor and roleColor

new_colors_logic = """
  static Color teamColor(Team team) {
    if (team == Team.mafia) return const Color(0xFF8B0000); // Always Dark Red
    if (team == Team.independent) return Colors.purpleAccent;
    return accent; // Citizens generally use the dynamic accent color
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return const Color(0xFF8B0000); // Always Dark Red
    if (role.team == Team.independent) return Colors.purpleAccent; // Joker
    if (role == Role.goodCitizen) return Colors.white; // Always White
    
    // Citizens with ability
    return accent; // Dynamic Theme Accent
  }
"""

# Replace existing teamColor and roleColor
# They currently look like:
#  static Color teamColor(Team team) {
#    if (team == Team.mafia) return mafiaPrimary;
#    if (team == Team.independent) return Colors.purpleAccent;
#    return citizensPrimary;
#  }
#
#  static Color roleColor(Role role) {
#    if (role.team == Team.mafia) return mafiaPrimary;
#    if (role.team == Team.independent) return Colors.purpleAccent;
#    if (role == Role.goodCitizen) return citizensPrimary;
#    return specialAction;
#  }

pattern = r'static Color teamColor\(Team team\) \{.*?return specialAction;\n  \}'
content = re.sub(pattern, new_colors_logic.strip(), content, flags=re.DOTALL)

with open('lib/presentation/theme/app_theme.dart', 'w') as f:
    f.write(content)
