import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class SettingsRepository {
  static const String _fileName = 'role_settings.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<Role, String>> loadCustomRoleNames() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return {};
      }
      final String contents = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(contents);
      
      final Map<Role, String> customNames = {};
      for (final entry in json.entries) {
        final role = Role.values.firstWhere((r) => r.name == entry.key);
        customNames[role] = entry.value.toString();
      }
      return customNames;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveCustomRoleNames(Map<Role, String> names) async {
    try {
      final file = await _file;
      final Map<String, String> json = {};
      for (final entry in names.entries) {
        json[entry.key.name] = entry.value;
      }
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Ignore
    }
  }
}
