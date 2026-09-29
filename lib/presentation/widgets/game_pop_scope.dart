import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class GamePopScope extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onExit;

  const GamePopScope({super.key, required this.child, this.onExit});

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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.redAccent, width: 1)),
            title: const Text('تأكيد الخروج',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
            content: const Text('هل تريد حقاً إنهاء اللعبة والعودة للرئيسية؟',
                style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء',
                      style: TextStyle(
                          color: Colors.white54, fontFamily: 'Cairo'))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('خروج',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          if (onExit != null) {
            await onExit!();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      },
      child: child,
    );
  }
}
