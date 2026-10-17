import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/application/interactive_prompts.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_dashboard_screen.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';

Map<String, List<PlayerActionPrompt>> moderatorPrompts(GameState s) =>
    switch (s.phase) {
      Phase.voting => InteractivePrompts.voting(s),
      Phase.night when s.round > 1 => InteractivePrompts.night(s),
      Phase.triggeredAbility => InteractivePrompts.retaliation(s),
      _ => {},
    };

/// Always rebuild the destination after a correction: local selections and
/// phase-specific animation cursors must not survive a restored checkpoint.
Widget moderatorDestination(GameState s, String? room) {
  if (s.phase == Phase.winCheck) {
    return GameOverScreen(interactiveSessionId: room);
  }
  if (room != null) return JudgeDashboardScreen(sessionId: room);
  return switch (s.phase) {
    Phase.roleReveal => const RoleRevealScreen(),
    Phase.voting ||
    Phase.elimination ||
    Phase.voteResolution => const VotingScreen(),
    Phase.night ||
    Phase.nightMafiaSheikh ||
    Phase.nightMafiaGirl ||
    Phase.nightNormalMafia ||
    Phase.nightCitizensGirl ||
    Phase.nightCitizensSheikh => const NightScreen(),
    Phase.triggeredAbility ||
    Phase.nightResolution ||
    Phase.dawn => const NightSummaryScreen(),
    _ => const DayScreen(),
  };
}

class ModeratorControls extends ConsumerStatefulWidget {
  const ModeratorControls({super.key, this.sessionId, this.enabled = true});
  final String? sessionId;
  final bool enabled;
  @override
  ConsumerState<ModeratorControls> createState() => _ModeratorControlsState();
}

class _ModeratorControlsState extends ConsumerState<ModeratorControls> {
  bool _busy = false;
  Future<void> _correct({String? kickId}) async {
    if (_busy || !widget.enabled) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(kickId == null ? 'التراجع خطوة؟' : 'طرد اللاعب؟'),
        content: Text(
          kickId == null
              ? 'ستعود حالة اللعب إلى الخطوة السابقة. في QR تُلغى طلبات المرحلة الحالية ويُطلب التصويت أو الحركة من جديد.'
              : 'سيخرج اللاعب من المباراة وتُعاد مراجعة شروط الفوز. يمكنك التراجع عن الطرد خلال اللعب.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    final controller = ref.read(gameOrchestratorProvider.notifier);
    final before = ref.read(gameOrchestratorProvider);
    GameState? undoTarget;
    try {
      if (kickId == null) {
        undoTarget = controller.undoStep();
      } else {
        controller.kickPlayer(kickId);
      }
      final corrected = ref.read(gameOrchestratorProvider);
      final room = widget.sessionId;
      if (room != null) {
        await ref
            .read(interactiveServiceProvider)
            .syncGameState(
              room,
              corrected,
              null,
              null,
              actionPrompts: moderatorPrompts(corrected),
              clearPrivateResults: true,
              moderatorRewind: kickId == null,
            );
      }
      if (!mounted) return;
      final destinationState = ref.read(gameOrchestratorProvider);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => moderatorDestination(destinationState, room),
        ),
        (_) => false,
      );
    } catch (error) {
      controller.restoreCheckpoint(before);
      if (widget.sessionId != null) {
        try {
          final recovered = await ref
              .read(interactiveServiceProvider)
              .reconcileHostState(widget.sessionId!);
          if (recovered != null) controller.restoreCheckpoint(recovered);
        } catch (_) {
          /* Keep the last confirmed local state. */
        }
      }
      if (undoTarget != null &&
          jsonEncode(ref.read(gameOrchestratorProvider).toJson()) ==
              jsonEncode(before.toJson())) {
        controller.returnUndoAfterFailedWrite(undoTarget);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تطبيق التعديل: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choosePlayer() async {
    final players = ref
        .read(gameOrchestratorProvider)
        .players
        .where((p) => !p.isKicked)
        .toList();
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(c).height * .6,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('طرد لاعب من المباراة'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: Text(players[i].name),
                    onTap: () => Navigator.pop(c, players[i].id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (id != null && mounted) await _correct(kickId: id);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(gameOrchestratorProvider);
    final enabled = widget.enabled && !_busy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'التراجع خطوة',
          onPressed:
              enabled && ref.read(gameOrchestratorProvider.notifier).canUndo
              ? () => _correct()
              : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          tooltip: 'طرد لاعب',
          onPressed: enabled ? _choosePlayer : null,
          icon: const Icon(Icons.person_remove_outlined),
        ),
      ],
    );
  }
}
