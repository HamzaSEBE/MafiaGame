import re

with open('lib/domain/rules/game_ruleset.dart', 'r') as f:
    content = f.read()

old_defaults = """  const AbilityRules({
    this.protectionTargetLimit = 1,
    this.silenceTargetLimit = 1,
    this.mafiaSheikhReveal = false,
    this.jokerReveal = false,
    this.citizenSheikhReveal = true,
    this.sniper = false,
  });"""

new_defaults = """  const AbilityRules({
    this.protectionTargetLimit = 1,
    this.silenceTargetLimit = 1,
    this.mafiaSheikhReveal = true,
    this.jokerReveal = false,
    this.citizenSheikhReveal = false,
    this.sniper = false,
  });"""

content = content.replace(old_defaults, new_defaults)

old_json = """      mafiaSheikhReveal: json['mafiaSheikhReveal'] ?? false,
      jokerReveal: json['jokerReveal'] ?? false,
      citizenSheikhReveal: json['citizenSheikhReveal'] ?? true,"""

new_json = """      mafiaSheikhReveal: json['mafiaSheikhReveal'] ?? true,
      jokerReveal: json['jokerReveal'] ?? false,
      citizenSheikhReveal: json['citizenSheikhReveal'] ?? false,"""

content = content.replace(old_json, new_json)

with open('lib/domain/rules/game_ruleset.dart', 'w') as f:
    f.write(content)
