import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';

import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class GamePopScope extends ConsumerWidget {
  final Widget child;
  final Future<void> Function()? onExit;

  const GamePopScope({super.key, required this.child, this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (onExit != null) {
          await onExit!();
          return;
        }

        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: context.visual.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.visual.accent, width: 1),
            ),
            title: const Text(
              'تأكيد الخروج',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'هل تريد حقاً إنهاء اللعبة والعودة للرئيسية؟',
              style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.visual.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'خروج',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          if (onExit != null) {
            await onExit!();
          } else {
            await ref.read(gameOrchestratorProvider.notifier).endGame();
            if (!context.mounted) return;
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
