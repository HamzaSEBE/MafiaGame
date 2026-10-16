class PlayerStats {
  final String name;
  final int gamesPlayed;
  final int mafiaWins;
  final int citizenWins;
  final int killedFirstNight;

  const PlayerStats({
    required this.name,
    this.gamesPlayed = 0,
    this.mafiaWins = 0,
    this.citizenWins = 0,
    this.killedFirstNight = 0,
  });

  PlayerStats copyWith({
    String? name,
    int? gamesPlayed,
    int? mafiaWins,
    int? citizenWins,
    int? killedFirstNight,
  }) {
    return PlayerStats(
      name: name ?? this.name,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      mafiaWins: mafiaWins ?? this.mafiaWins,
      citizenWins: citizenWins ?? this.citizenWins,
      killedFirstNight: killedFirstNight ?? this.killedFirstNight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gamesPlayed': gamesPlayed,
      'mafiaWins': mafiaWins,
      'citizenWins': citizenWins,
      'killedFirstNight': killedFirstNight,
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      name: json['name'] as String,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      mafiaWins: json['mafiaWins'] as int? ?? 0,
      citizenWins: json['citizenWins'] as int? ?? 0,
      killedFirstNight: json['killedFirstNight'] as int? ?? 0,
    );
  }
}
