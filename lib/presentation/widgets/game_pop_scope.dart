import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

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
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('إنهاء اللعبة؟', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            content: const Text('هل تريد الخروج من اللعبة والعودة للرئيسية؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: child,
    );
  }
}