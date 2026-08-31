import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GameRecord {
  final String id;
  final DateTime date;
  final String winningTeam; // 'مافيا' or 'مواطنون'
  final List<PlayerRecord> players;

  GameRecord({
    required this.id,
    required this.date,
    required this.winningTeam,
    required this.players,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'winningTeam': winningTeam,
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    winningTeam: json['winningTeam'],
    players: (json['players'] as List).map((p) => PlayerRecord.fromJson(p)).toList(),
  );
}

class PlayerRecord {
  final String name;
  final String roleName;
  final String team;

  PlayerRecord({
    required this.name,
    required this.roleName,
    required this.team,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'roleName': roleName,
    'team': team,
  };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
    name: json['name'],
    roleName: json['roleName'],
    team: json['team'],
  );
}

class HistoryRepository {
  static const String _fileName = 'games_history.json';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<GameRecord>> getHistory() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((j) => GameRecord.fromJson(j)).toList().reversed.toList(); // Newest first
    } catch (e) {
      return [];
    }
  }

  Future<void> addGame(GameRecord game) async {
    try {
      final file = await _file;
      List<GameRecord> currentHistory = [];
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        currentHistory = jsonList.map((j) => GameRecord.fromJson(j)).toList();
      }
      currentHistory.add(game);
      
      final String newContents = jsonEncode(currentHistory.map((g) => g.toJson()).toList());
      await file.writeAsString(newContents);
    } catch (e) {
      // ignore
    }
  }
  
  Future<void> clearHistory() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore
    }
  }
}
