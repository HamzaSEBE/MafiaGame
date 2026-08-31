import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';

final playerStatsRepoProvider = Provider((ref) => PlayerStatsRepository());

class PlayerStatsRepository {
  static const String _fileName = 'player_stats_v1.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<PlayerStats>> loadStats() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => PlayerStats.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveStats(List<PlayerStats> stats) async {
    try {
      final file = await _file;
      final jsonList = stats.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // Ignore
    }
  }

  Future<void> updateStatsForPlayer(String name, {
    bool played = false,
    bool wonAsMafia = false,
    bool wonAsCitizen = false,
    bool diedFirstNight = false,
  }) async {
    final currentStats = await loadStats();
    int index = currentStats.indexWhere((s) => s.name == name);
    
    PlayerStats stat;
    if (index == -1) {
      stat = PlayerStats(name: name);
      currentStats.add(stat);
      index = currentStats.length - 1;
    } else {
      stat = currentStats[index];
    }

    stat = stat.copyWith(
      gamesPlayed: played ? stat.gamesPlayed + 1 : stat.gamesPlayed,
      mafiaWins: wonAsMafia ? stat.mafiaWins + 1 : stat.mafiaWins,
      citizenWins: wonAsCitizen ? stat.citizenWins + 1 : stat.citizenWins,
      killedFirstNight: diedFirstNight ? stat.killedFirstNight + 1 : stat.killedFirstNight,
    );

    currentStats[index] = stat;
    await saveStats(currentStats);
  }
}
