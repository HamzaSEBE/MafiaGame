import 'dart:io';

void main() {
  final file = File('lib/domain/engine/timeline_generator.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("voteMap.putIfAbsent(v.targetId, () => []).add(getPlayerName(v.actorId));", "if (v.targetId != null) voteMap.putIfAbsent(v.targetId!, () => []).add(getPlayerName(v.actorId));");
  file.writeAsStringSync(content);
}