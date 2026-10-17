import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter/material.dart';

import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';
import 'package:mafia_nightfall/presentation/setup/rule_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/data/repositories/player_profiles_repository.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_lobby_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final bool isInteractive;
  final bool rolesOnly;
  final String? rematchSessionId;
  const SetupScreen({
    super.key,
    required this.isInteractive,
    this.rolesOnly = false,
    this.rematchSessionId,
  });

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  int _currentTab = 0; // 0 = players, 1 = roles

  List<String> _savedPlayers = [];
  late final PlayerProfilesRepository _profilesRepo =
      PlayerProfilesRepository();

  final Map<Role, int> _roleConfig = {
    Role.mafiaSheikh: 0,
    Role.mafiaGirl: 0,
    Role.normalMafia: 0,
    Role.citizensSheikh: 0,
    Role.citizensGirl: 0,
    Role.citizensBoy: 0,
    Role.goodCitizen: 0,
    Role.joker: 0,
  };

  int get _totalRoles => _roleConfig.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    if (widget.rolesOnly) {
      _currentTab = 1;
      for (final p in ref.read(gameOrchestratorProvider).players) {
        _roleConfig[p.role] = (_roleConfig[p.role] ?? 0) + 1;
      }
    } else {
      _loadProfiles();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    List<String> profiles;
    try {
      profiles = await _profilesRepo.loadSavedPlayers();
    } catch (_) {
      if (mounted) _showError('تعذر تحميل الأسماء المحفوظة.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _savedPlayers = profiles;
    });
  }

  void _addPlayer(String name) {
    final players = ref.read(gameOrchestratorProvider).players;
    if (players.any((p) => p.name == name.trim())) {
      _showError('هذا اللاعب مضاف مسبقاً!');
      return;
    }
    if (name.trim().isEmpty) return;
    ref.read(gameOrchestratorProvider.notifier).addPlayer(name.trim());
    _nameController.clear();
    FocusScope.of(context).unfocus();

    // Save to persistent storage immediately
    if (!_savedPlayers.contains(name.trim())) {
      setState(() => _savedPlayers.add(name.trim()));
      _profilesRepo.savePlayers(List.of(_savedPlayers)).catchError((Object _) {
        if (mounted) _showError('تعذر حفظ الأسماء. أعد المحاولة.');
      });
    }
  }

  void _confirmDeleteSavedPlayer(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.visual.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف اللاعب المحفوظ؟',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل تريد حذف "$name" من القائمة المحفوظة؟',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.visual.accent,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _savedPlayers.remove(name));
              _profilesRepo.savePlayers(List.of(_savedPlayers)).catchError((
                Object _,
              ) {
                if (mounted) _showError('تعذر حفظ الأسماء. أعد المحاولة.');
              });
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  void _removePlayer(int index) {
    final players = ref.read(gameOrchestratorProvider).players;
    ref.read(gameOrchestratorProvider.notifier).removePlayer(players[index].id);
  }

  void _startGame(bool isInteractive) {
    final players = ref.read(gameOrchestratorProvider).players;
    if (players.isEmpty) {
      _showError('أضف لاعبين أولاً');
      return;
    }
    if (_totalRoles != players.length) {
      _showError(
        'عدد الأدوار ($_totalRoles) لا يساوي عدد اللاعبين (${players.length})',
      );
      return;
    }

    final mafiaCount =
        _roleConfig[Role.mafiaSheikh]! +
        _roleConfig[Role.mafiaGirl]! +
        _roleConfig[Role.normalMafia]!;
    final citizenCount =
        _roleConfig[Role.citizensSheikh]! +
        _roleConfig[Role.citizensGirl]! +
        _roleConfig[Role.citizensBoy]! +
        _roleConfig[Role.goodCitizen]!;

    if (mafiaCount == 0) {
      _showError('يجب إضافة مافيا واحدة على الأقل لبدء اللعبة!');
      return;
    }
    if (citizenCount == 0) {
      _showError('يجب إضافة مواطن واحد على الأقل لبدء اللعبة!');
      return;
    }

    // Shuffle the player order for fully random reveal sequence
    ref.read(gameOrchestratorProvider.notifier).shufflePlayers();

    final error = ref
        .read(gameOrchestratorProvider.notifier)
        .assignRoles(_roleConfig);
    if (error != null) {
      _showError(error);
      return;
    }

    if (widget.rolesOnly) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoleReviewScreen(
            rematchSessionId: widget.rematchSessionId,
            isRematch: true,
          ),
        ),
      );
    } else if (isInteractive) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const JudgeLobbyScreen()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleReviewScreen()),
      );
    }
  }

  void _autoDistributeRoles() {
    final players = ref.read(gameOrchestratorProvider).players;
    final total = players.length;
    if (total == 0) return;

    for (var r in Role.values) {
      _roleConfig[r] = 0;
    }

    int mafiaTotal = (total / 3).floor();
    if (mafiaTotal < 1 && total > 0) mafiaTotal = 1;

    int citizensTotal = total - mafiaTotal;

    if (mafiaTotal >= 1) _roleConfig[Role.mafiaSheikh] = 1;
    if (mafiaTotal >= 2) _roleConfig[Role.mafiaGirl] = 1;
    if (mafiaTotal >= 3) _roleConfig[Role.normalMafia] = mafiaTotal - 2;

    if (citizensTotal >= 1) _roleConfig[Role.citizensSheikh] = 1;
    if (citizensTotal >= 2) _roleConfig[Role.citizensGirl] = 1;
    if (citizensTotal >= 3) _roleConfig[Role.citizensBoy] = 1;

    if (citizensTotal > 3) {
      _roleConfig[Role.goodCitizen] = citizensTotal - 3;
    }

    setState(() {});
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: context.visual.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final players = ref.watch(gameOrchestratorProvider).players;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 1.5,
                  colors: [
                    context.visual.surfaceHigh,
                    context.visual.surface,
                    context.visual.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: context.visual.accent,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'تجهيز المعركة',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            shadows: [
                              Shadow(
                                color: context.visual.accent,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),

                // Tabs
                if (!widget.rolesOnly)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: 'اللاعبين (${players.length})',
                            icon: Icons.people,
                            selected: _currentTab == 0,
                            onTap: () => setState(() => _currentTab = 0),
                          ),
                          _TabButton(
                            label: 'الأدوار ($_totalRoles)',
                            icon: Icons.admin_panel_settings,
                            selected: _currentTab == 1,
                            onTap: () => setState(() => _currentTab = 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentTab == 0
                        ? _PlayersTab(
                            players: players,
                            savedPlayers: _savedPlayers,
                            nameController: _nameController,
                            onAdd: _addPlayer,
                            onRemove: _removePlayer,
                            onDeleteSaved: _confirmDeleteSavedPlayer,
                          )
                        : _RolesTab(
                            roleConfig: _roleConfig,
                            playerCount: players.length,
                            totalRoles: _totalRoles,
                            onChanged: (r, c) =>
                                setState(() => _roleConfig[r] = c),
                            onAutoDistribute: _autoDistributeRoles,
                          ),
                  ),
                ),

                // Rule Settings Button
                if (!widget.rolesOnly)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.settings, color: context.visual.accent),
                      label: const Text(
                        'قوانين وإعدادات اللعبة',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: context.visual.accent,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RuleSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                // Start Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            (players.length >= 4 &&
                                _totalRoles == players.length)
                            ? (widget.isInteractive
                                  ? [
                                      context.visual.primaryCardStart,
                                      context.visual.primaryCardEnd,
                                    ]
                                  : [
                                      context.visual.secondaryCardStart,
                                      context.visual.secondaryCardEnd,
                                    ])
                            : [Colors.grey.shade800, Colors.grey.shade900],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                          (players.length >= 4 && _totalRoles == players.length)
                          ? [
                              BoxShadow(
                                color: widget.isInteractive
                                    ? context.visual.glowColor
                                    : context.visual.secondaryCardStart,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap:
                            (players.length >= 4 &&
                                _totalRoles == players.length)
                            ? () => _startGame(widget.isInteractive)
                            : () {
                                if (players.length < 4) {
                                  _showError('يجب إضافة 4 لاعبين على الأقل');
                                } else {
                                  _showError(
                                    'عدد الأدوار لا يطابق عدد اللاعبين',
                                  );
                                }
                              },
                        child: Center(
                          child: Text(
                            widget.isInteractive
                                ? 'بدء اللعب التفاعلي (QR)'
                                : 'بدء اللعب',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? context.visual.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? context.visual.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? context.visual.accent : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: selected ? context.visual.accent : Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PlayersTab extends StatelessWidget {
  final List players;
  final List<String> savedPlayers;
  final TextEditingController nameController;
  final void Function(String) onAdd;
  final void Function(int) onRemove;
  final void Function(String) onDeleteSaved;

  const _PlayersTab({
    required this.players,
    required this.savedPlayers,
    required this.nameController,
    required this.onAdd,
    required this.onRemove,
    required this.onDeleteSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Field
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم اللاعب...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontFamily: 'Cairo',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: onAdd,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.visual.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => onAdd(nameController.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Saved Players
          if (savedPlayers.isNotEmpty) ...[
            Text(
              'اللاعبون المحفوظون:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: savedPlayers.length,
                itemBuilder: (ctx, i) {
                  final sp = savedPlayers[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Builder(
                      builder: (ctx) {
                        final isAdded = players.any((p) => p.name == sp);
                        return GestureDetector(
                          onLongPress: () => onDeleteSaved(sp),
                          child: ActionChip(
                            backgroundColor: isAdded
                                ? context.visual.accent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: isAdded
                                  ? context.visual.accent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            label: Text(
                              sp,
                              style: TextStyle(
                                color: isAdded
                                    ? context.visual.accent
                                    : Colors.white70,
                                fontFamily: 'Cairo',
                                fontWeight: isAdded
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onPressed: isAdded ? null : () => onAdd(sp),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Player List
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.visual.accent.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: context.visual.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      players[index].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 18,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => onRemove(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesTab extends StatelessWidget {
  final Map<Role, int> roleConfig;
  final int playerCount;
  final int totalRoles;
  final void Function(Role, int) onChanged;
  final VoidCallback onAutoDistribute;

  const _RolesTab({
    required this.roleConfig,
    required this.playerCount,
    required this.totalRoles,
    required this.onChanged,
    required this.onAutoDistribute,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = playerCount - totalRoles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: remaining == 0
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : context.visual.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: remaining == 0
                    ? Colors.greenAccent.withValues(alpha: 0.3)
                    : context.visual.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'الأدوار الموزعة:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (playerCount > 0)
                        ElevatedButton.icon(
                          onPressed: onAutoDistribute,
                          icon: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'توزيع ذكي',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.visual.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 30),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$totalRoles / $playerCount',
                  style: TextStyle(
                    color: remaining == 0
                        ? Colors.greenAccent
                        : context.visual.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'فريق المافيا',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                _buildRoleRow(context, Role.mafiaSheikh),
                _buildRoleRow(context, Role.mafiaGirl),
                _buildRoleRow(context, Role.normalMafia),
                const Divider(color: Colors.white10, height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'فريق المواطنين',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                _buildRoleRow(context, Role.citizensSheikh),
                _buildRoleRow(context, Role.citizensGirl),
                _buildRoleRow(context, Role.citizensBoy),
                _buildRoleRow(context, Role.goodCitizen),
                const Divider(color: Colors.white10, height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'المستقلين',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                _buildRoleRow(context, Role.joker),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(BuildContext context, Role role) {
    final count = roleConfig[role]!;
    final color = role.team == Team.mafia
        ? Colors.redAccent
        : role.team == Team.independent
        ? Colors.purpleAccent
        : Colors.blueAccent;
    final icon = role.team == Team.mafia
        ? Icons.local_fire_department
        : role.team == Team.independent
        ? Icons.sentiment_very_dissatisfied
        : Icons.shield;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0
            ? color.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.roleName(role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  AppTheme.roleAbilityDescription(role),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: Colors.white54,
                  onPressed: count > 0
                      ? () => onChanged(role, count - 1)
                      : null,
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    color: count > 0 ? color : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: Colors.white,
                  onPressed: () => onChanged(role, count + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
