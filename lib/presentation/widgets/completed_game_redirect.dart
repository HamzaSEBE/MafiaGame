import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';

/// An ended checkpoint must never expose another timer, vote or night action.
/// Hidden routes wait: a voting/reveal route may still be presenting the result.
class CompletedGameRedirect extends ConsumerStatefulWidget {
  const CompletedGameRedirect({super.key, this.interactiveSessionId});
  final String? interactiveSessionId;

  @override
  ConsumerState<CompletedGameRedirect> createState() =>
      _CompletedGameRedirectState();
}

class _CompletedGameRedirectState extends ConsumerState<CompletedGameRedirect> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(gameOrchestratorProvider).phase;
    if (!_scheduled &&
        phase == Phase.winCheck &&
        ModalRoute.of(context)?.isCurrent == true) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(gameOrchestratorProvider).phase != Phase.winCheck ||
            ModalRoute.of(context)?.isCurrent != true) {
          _scheduled = false;
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              interactiveSessionId: widget.interactiveSessionId,
            ),
          ),
          (route) => false,
        );
      });
    }
    return const Scaffold(
      body: Center(child: Text('المباراة انتهت. جارٍ عرض النتيجة…')),
    );
  }
}
