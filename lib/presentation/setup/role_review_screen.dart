import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';

class RoleReviewScreen extends ConsumerStatefulWidget {
  final bool returnToLobby;

  const RoleReviewScreen({super.key, this.returnToLobby = false});

  @override
  ConsumerState<RoleReviewScreen> createState() => _RoleReviewScreenState();
}

class _RoleReviewScreenState extends ConsumerState<RoleReviewScreen> {
  Player? _selectedPlayer;

  void _shuffleAgain() {
    ref.read(gameOrchestratorProvider.notifier).shuffleAssignedRoles();
    setState(() => _selectedPlayer = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم إعادة التوزيع عشوائياً 🎲',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green),
    );
  }

  void _onPlayerTapped(Player p) {
    if (_selectedPlayer == null) {
      setState(() => _selectedPlayer = p);
    } else {
      if (_selectedPlayer!.id == p.id) {
        setState(() => _selectedPlayer = null); // deselect
      } else {
        // Swap roles
        final roleA = _selectedPlayer!.role;
        final roleB = p.role;

        ref
            .read(gameOrchestratorProvider.notifier)
            .updatePlayer(_selectedPlayer!.copyWith(role: roleB));
        ref
            .read(gameOrchestratorProvider.notifier)
            .updatePlayer(p.copyWith(role: roleA));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تبديل الأدوار بنجاح 🔄',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.blueAccent,
              duration: Duration(seconds: 1)),
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
                    const Icon(Icons.info_outline, color: Colors.orangeAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedPlayer == null
                            ? 'اضغط على أي لاعب لتحديده، ثم اضغط على لاعب آخر لتبديل أدوارهما.'
                            : 'تم تحديد ${_selectedPlayer!.name}. اضغط على لاعب آخر للتبديل.',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Cairo',
                            fontSize: 13),
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
                      onTap: () => _onPlayerTapped(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? roleColor.withValues(alpha: 0.2)
                              : AppTheme.surface,
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
                              backgroundImage:
                                  AssetImage(AppTheme.roleImage(p.role)),
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
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        AppTheme.roleArabicName(p.role),
                                        style: TextStyle(
                                            color: roleColor,
                                            fontFamily: 'Cairo',
                                            fontSize: 11),
                                      ),
                                      if (p.hasSniper) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.my_location, color: Colors.amberAccent, size: 12),
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
                  color: AppTheme.surfaceHigh,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shuffleAgain,
                          icon: const Icon(Icons.shuffle,
                              color: Colors.orangeAccent, size: 20),
                          label: const Text('إعادة التوزيع',
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orangeAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.returnToLobby) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const RoleRevealScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 20),
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
                            backgroundColor: AppTheme.mafiaPrimary,
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
