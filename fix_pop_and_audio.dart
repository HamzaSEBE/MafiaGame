import 'dart:io';

void main() {
  final homeFile = File('lib/presentation/home/home_screen.dart');
  var content = homeFile.readAsStringSync();
  content = content.replaceAll("ref.read(audioManagerProvider).startAmbience();", "// ref.read(audioManagerProvider).startAmbience();");
  homeFile.writeAsStringSync(content);
  print('Disabled home ambience');

  final scopeFile = File('lib/presentation/widgets/game_pop_scope.dart');
  var scopeContent = scopeFile.readAsStringSync();
  // Fixing the pop until to pushAndRemoveUntil home screen and fixing arabic text
  final correctScope = """
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class GamePopScope extends StatelessWidget {
  final Widget child;

  const GamePopScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent, width: 1)),
            title: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            content: const Text('هل تريد حقاً إنهاء اللعبة والعودة للرئيسية؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true), 
                child: const Text('خروج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        }
      },
      child: child,
    );
  }
}
""";
  scopeFile.writeAsStringSync(correctScope);
  print('Fixed GamePopScope');
}