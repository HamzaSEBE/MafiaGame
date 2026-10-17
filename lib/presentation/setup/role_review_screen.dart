import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';

class RoleReviewScreen extends ConsumerStatefulWidget {
  final bool returnToLobby;
  final bool isRematch;
  final String? rematchSessionId;

  const RoleReviewScreen({
    super.key,
    this.returnToLobby = false,
    this.isRematch = false,
    this.rematchSessionId,
  });

  @override
  ConsumerState<RoleReviewScreen> createState() => _RoleReviewScreenState();
}

class _RoleReviewScreenState extends ConsumerState<RoleReviewScreen> {
  Player? _selectedPlayer;
  bool _starting = false;
  Future<void> _startRematch() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final room = widget.rematchSessionId!;
      await ref
          .read(interactiveServiceProvider)
          .syncGameState(
            room,
            ref.read(gameOrchestratorProvider),
            null,
            null,
            isRematch: true,
            clearPrivateResults: true,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => JudgeDashboardScreen(sessionId: room),
        ),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر بدء الإعادة: $error')));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _shuffleAgain() {
    ref.read(gameOrchestratorProvider.notifier).shuffleAssignedRoles();
    setState(() => _selectedPlayer = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إعادة التوزيع عشوائياً 🎲',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onPlayerTapped(Player p) {
    if (_selectedPlayer == null) {
      setState(() => _selectedPlayer = p);
    } else {
      if (_selectedPlayer!.id == p.id) {
        setState(() => _selectedPlayer = null); // deselect
      } else {
        // Swap role and sniper assignment together in one state update.
        ref
            .read(gameOrchestratorProvider.notifier)
            .swapPlayerRoles(_selectedPlayer!.id, p.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تبديل الأدوار بنجاح 🔄',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 1),
          ),
        );
        setState(() => _selectedPlayer = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final state = ref.watch(gameOrchestratorProvider);
    final players = state.players;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.returnToLobby
              ? 'مراجعة الأدوار قبل بدء اللعبة'
              : 'مراجعة الأدوار (للحكم)',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black45,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: context.visual.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedPlayer == null
                            ? 'اضغط على أي لاعب لتحديده، ثم اضغط على لاعب آخر لتبديل أدوارهما.'
                            : 'تم تحديد ${_selectedPlayer!.name}. اضغط على لاعب آخر للتبديل.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    final isSelected = _selectedPlayer?.id == p.id;
                    final roleColor = AppTheme.roleColor(p.role);

                    return GestureDetector(
                      onTap: _starting ? null : () => _onPlayerTapped(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? roleColor.withValues(alpha: 0.2)
                              : context.visual.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? roleColor
                                : roleColor.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: roleColor.withValues(alpha: 0.2),
                              backgroundImage: AssetImage(
                                AppTheme.roleImage(p.role),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        context.roleName(p.role),
                                        style: TextStyle(
                                          color: roleColor,
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (p.hasSniper) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.my_location,
                                          color: Colors.amberAccent,
                                          size: 12,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.visual.surfaceHigh,
                  border: const Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _starting ? null : _shuffleAgain,
                          icon: Icon(
                            Icons.shuffle,
                            color: context.visual.accent,
                            size: 20,
                          ),
                          label: Text(
                            'إعادة التوزيع',
                            style: TextStyle(
                              color: context.visual.accent,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.visual.accent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _starting
                              ? null
                              : () {
                                  if (widget.rematchSessionId != null) {
                                    _startRematch();
                                  } else if (widget.returnToLobby) {
                                    Navigator.of(context).pop();
                                  } else if (widget.isRematch) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RoleRevealScreen(),
                                      ),
                                      (_) => false,
                                    );
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RoleRevealScreen(),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            widget.returnToLobby
                                ? 'حفظ والعودة إلى اللوبي'
                                : 'بدء اللعبة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.visual.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
