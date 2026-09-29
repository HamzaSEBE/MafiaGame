import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = file.readAsStringSync();
  
  // Remove the badly placed one
  final badInjectStart = content.indexOf("  void _confirmExit(BuildContext context, WidgetRef ref) {");
  if (badInjectStart != -1) {
    final badInjectEnd = content.indexOf("}\n}\n", badInjectStart) + 1; // remove the injected code
    content = content.replaceRange(badInjectStart, badInjectEnd, "");
  }
  
  // Inject before build
  final buildStart = content.indexOf("Widget build(BuildContext context) {");
  final codeToInject = """
  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إنهاء اللعبة؟', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameOrchestratorProvider.notifier).resetGame();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإنهاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  """;
  content = content.replaceRange(buildStart, buildStart, codeToInject);
  file.writeAsStringSync(content);
}