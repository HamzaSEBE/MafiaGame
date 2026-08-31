import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlayerProfilesRepository {
  static const String _fileName = 'player_profiles.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<String>> loadSavedPlayers() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePlayers(List<String> players) async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(players));
    } catch (e) {
      // Ignore
    }
  }
}
