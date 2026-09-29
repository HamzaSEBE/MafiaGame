import 'dart:io';

void main() {
  final file = File('lib/presentation/setup/setup_screen.dart');
  var content = file.readAsStringSync();
  
  // Fix adding duplicates
  content = content.replaceAll(
    "void _addPlayer(String name) {", 
    "void _addPlayer(String name) {\n    final players = ref.read(gameOrchestratorProvider).players;\n    if (players.any((p) => p.name == name.trim())) {\n      _showError('هذا اللاعب مضاف مسبقاً!');\n      return;\n    }"
  );
  
  // Update the ActionChip in _PlayersTab to highlight
  final oldChip = """
                    child: ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      label: Text(sp, style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                      onPressed: () => onAdd(sp),
                    ),
""";
  final newChip = """
                    child: Builder(
                      builder: (ctx) {
                        final isAdded = players.any((p) => p.name == sp);
                        return ActionChip(
                          backgroundColor: isAdded ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(color: isAdded ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.1)),
                          label: Text(sp, style: TextStyle(color: isAdded ? Colors.orangeAccent : Colors.white70, fontFamily: 'Cairo', fontWeight: isAdded ? FontWeight.bold : FontWeight.normal)),
                          onPressed: isAdded ? null : () => onAdd(sp),
                        );
                      },
                    ),
""";
  content = content.replaceFirst(oldChip, newChip);
  file.writeAsStringSync(content);
}