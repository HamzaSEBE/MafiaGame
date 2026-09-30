class VictoryRules {
  final bool classicVictory;
  final bool initialMafiaParity;
  final bool correctMafiaExecutions;
  final int requiredCorrectExecutions;

  const VictoryRules({
    this.classicVictory = true,
    this.initialMafiaParity = false,
    this.correctMafiaExecutions = false,
    this.requiredCorrectExecutions = 3,
  });

  Map<String, dynamic> toJson() => {
    'classicVictory': classicVictory,
    'initialMafiaParity': initialMafiaParity,
    'correctMafiaExecutions': correctMafiaExecutions,
    'requiredCorrectExecutions': requiredCorrectExecutions,
  };

  factory VictoryRules.fromJson(Map<String, dynamic> json) => VictoryRules(
    classicVictory: json['classicVictory'] ?? true,
    initialMafiaParity: json['initialMafiaParity'] ?? false,
    correctMafiaExecutions: json['correctMafiaExecutions'] ?? false,
    requiredCorrectExecutions: json['requiredCorrectExecutions'] ?? 3,
  );
}

class AbilityRules {
  final int repeatedTargetLimit; // -1 for Unlimited
  final bool mafiaSheikhReveal;
  final bool jokerReveal;
  final bool citizenSheikhReveal;
  final bool sniper;

  const AbilityRules({
    this.repeatedTargetLimit = 1,
    this.mafiaSheikhReveal = false,
    this.jokerReveal = false,
    this.citizenSheikhReveal = true,
    this.sniper = false,
  });

  Map<String, dynamic> toJson() => {
    'repeatedTargetLimit': repeatedTargetLimit,
    'mafiaSheikhReveal': mafiaSheikhReveal,
    'jokerReveal': jokerReveal,
    'citizenSheikhReveal': citizenSheikhReveal,
    'sniper': sniper,
  };

  factory AbilityRules.fromJson(Map<String, dynamic> json) => AbilityRules(
    repeatedTargetLimit: json['repeatedTargetLimit'] ?? 1,
    mafiaSheikhReveal: json['mafiaSheikhReveal'] ?? false,
    jokerReveal: json['jokerReveal'] ?? false,
    citizenSheikhReveal: json['citizenSheikhReveal'] ?? true,
    sniper: json['sniper'] ?? false,
  );
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
