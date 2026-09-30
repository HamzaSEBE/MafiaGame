enum VictoryMode {
  classic,
  equalCount,
  exactMafiaExecutions
}

class VictoryRules {
  final VictoryMode mode;
  final int requiredCorrectExecutions;

  const VictoryRules({
    this.mode = VictoryMode.classic,
    this.requiredCorrectExecutions = 3,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'requiredCorrectExecutions': requiredCorrectExecutions,
    // Keep these for backward compatibility when loading old saves
    'classicVictory': mode == VictoryMode.classic,
    'initialMafiaParity': mode == VictoryMode.equalCount,
    'correctMafiaExecutions': mode == VictoryMode.exactMafiaExecutions,
  };

  factory VictoryRules.fromJson(Map<String, dynamic> json) {
    VictoryMode parsedMode = VictoryMode.classic;
    
    // Handle new format
    if (json.containsKey('mode')) {
      parsedMode = VictoryMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => VictoryMode.classic,
      );
    } 
    // Handle legacy format
    else {
      if (json['correctMafiaExecutions'] == true) {
        parsedMode = VictoryMode.exactMafiaExecutions;
      } else if (json['initialMafiaParity'] == true) {
        parsedMode = VictoryMode.equalCount;
      }
    }

    return VictoryRules(
      mode: parsedMode,
      requiredCorrectExecutions: json['requiredCorrectExecutions'] ?? 3,
    );
  }
}

class AbilityRules {
  final int protectionTargetLimit; // -1 for Unlimited
  final int silenceTargetLimit; // -1 for Unlimited
  final bool mafiaSheikhReveal;
  final bool jokerReveal;
  final bool citizenSheikhReveal;
  final bool sniper;

  const AbilityRules({
    this.protectionTargetLimit = 1,
    this.silenceTargetLimit = 1,
    this.mafiaSheikhReveal = false,
    this.jokerReveal = false,
    this.citizenSheikhReveal = true,
    this.sniper = false,
  });

  Map<String, dynamic> toJson() => {
    'protectionTargetLimit': protectionTargetLimit,
    'silenceTargetLimit': silenceTargetLimit,
    'mafiaSheikhReveal': mafiaSheikhReveal,
    'jokerReveal': jokerReveal,
    'citizenSheikhReveal': citizenSheikhReveal,
    'sniper': sniper,
    // Legacy support
    'repeatedTargetLimit': protectionTargetLimit,
  };

  factory AbilityRules.fromJson(Map<String, dynamic> json) {
    // Migration from old 'repeatedTargetLimit'
    int pLimit = json['protectionTargetLimit'] ?? json['repeatedTargetLimit'] ?? 1;
    int sLimit = json['silenceTargetLimit'] ?? json['repeatedTargetLimit'] ?? 1;

    return AbilityRules(
      protectionTargetLimit: pLimit,
      silenceTargetLimit: sLimit,
      mafiaSheikhReveal: json['mafiaSheikhReveal'] ?? false,
      jokerReveal: json['jokerReveal'] ?? false,
      citizenSheikhReveal: json['citizenSheikhReveal'] ?? true,
      sniper: json['sniper'] ?? false,
    );
  }
}

class GameRuleset {
  final bool allowMultipleAssassinationsPerNight;
  final VictoryRules victoryRules;
  final AbilityRules abilityRules;

  const GameRuleset({
    this.allowMultipleAssassinationsPerNight = false,
    this.victoryRules = const VictoryRules(),
    this.abilityRules = const AbilityRules(),
  });

  Map<String, dynamic> toJson() => {
    'allowMultipleAssassinationsPerNight': allowMultipleAssassinationsPerNight,
    'victoryRules': victoryRules.toJson(),
    'abilityRules': abilityRules.toJson(),
  };

  factory GameRuleset.fromJson(Map<String, dynamic> json) => GameRuleset(
    allowMultipleAssassinationsPerNight: json['allowMultipleAssassinationsPerNight'] ?? false,
    victoryRules: json['victoryRules'] != null ? VictoryRules.fromJson(json['victoryRules']) : const VictoryRules(),
    abilityRules: json['abilityRules'] != null ? AbilityRules.fromJson(json['abilityRules']) : const AbilityRules(),
  );
}
