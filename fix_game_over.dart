import 'dart:io';
void main() {
  final file = File('lib/presentation/game_over/game_over_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  final stackStart = "Stack(\n        children: [";
  final stackStartNew = "Stack(\n        children: [\n          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))),";
  content = content.replaceAll(stackStart, stackStartNew);
  file.writeAsStringSync(content);
}