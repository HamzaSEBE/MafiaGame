import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';

import 'package:mafia_nightfall/data/repositories/player_profiles_repository.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _currentTab = 0; // 0 = players, 1 = roles
  
  List<String> _savedPlayers = [];
  final PlayerProfilesRepository _profilesRepo = PlayerProfilesRepository();

  // Role config: how many of each role
  final Map<Role, int> _roleConfig = {
    Role.mafiaSheikh:    0,
    Role.mafiaGirl:      0,
    Role.normalMafia:    0,
    Role.citizensSheikh: 0,
    Role.citizensGirl:   0,
    Role.citizensBoy:    0,
    Role.goodCitizen:    0,
  };

  int get _totalRoles => _roleConfig.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final loaded = await _profilesRepo.loadSavedPlayers();
    setState(() {
      _savedPlayers = loaded;
    });
  }

  Future<void> _addSavedPlayer(String name) async {
    if (!_savedPlayers.contains(name)) {
      setState(() {
        _savedPlayers.add(name);
      });
      await _profilesRepo.savePlayers(_savedPlayers);
    }
  }

  Future<void> _removeSavedPlayer(String name) async {
    setState(() {
      _savedPlayers.remove(name);
    });
    await _profilesRepo.savePlayers(_savedPlayers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    ref.read(gameOrchestratorProvider.notifier).addPlayer(name);
    _addSavedPlayer(name);
    _nameController.clear();
  }
  
  void _addPlayerDirectly(String name) {
    ref.read(gameOrchestratorProvider.notifier).addPlayer(name);
  }

  void _startGame() {
    final players = ref.read(gameOrchestratorProvider).players;
    if (players.isEmpty) {
      _showError('أضف لاعبين أولاً');
      return;
    }
    if (_totalRoles != players.length) {
      _showError('عدد الأدوار ($_totalRoles) لا يساوي عدد اللاعبين (${players.length})');
      return;
    }
    final error = ref.read(gameOrchestratorProvider.notifier).assignRoles(_roleConfig);
    if (error != null) {
      _showError(error);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleRevealScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.mafiaAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final players = gameState.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد اللعبة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _TabButton(label: 'اللاعبون (${players.length})', selected: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
                const SizedBox(width: 10),
                _TabButton(label: 'الأدوار ($_totalRoles)', selected: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _currentTab == 0
                ? _NamesTab(
                    players: players.map((p) => p.name).toList(),
                    savedPlayers: _savedPlayers,
                    nameController: _nameController,
                    onAdd: _addPlayer,
                    onAddSaved: _addPlayerDirectly,
                    onRemoveSaved: _removeSavedPlayer,
                    onRemove: (index) {
                      final player = players[index];
                      ref.read(gameOrchestratorProvider.notifier).removePlayer(player.id);
                    },
                  )
                : _RolesTab(
                    roleConfig: _roleConfig,
                    playerCount: players.length,
                    totalRoles: _totalRoles,
                    onChanged: (role, value) {
                      setState(() => _roleConfig[role] = value);
                    },
                  ),
          ),
          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (players.isNotEmpty && _totalRoles == players.length)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${players.length} لاعب · $_totalRoles دور — جاهز للبدء',
                          style: const TextStyle(color: AppTheme.success, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: (players.length >= 4 && _totalRoles == players.length) ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mafiaPrimary,
                    disabledBackgroundColor: AppTheme.surface,
                  ),
                  child: const Text('توزيع الأدوار والبدء'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Players Tab ──────────────────────────────────────────────────────────────
class _NamesTab extends StatelessWidget {
  final List<String> players;
  final List<String> savedPlayers;
  final TextEditingController nameController;
  final VoidCallback onAdd;
  final void Function(String) onAddSaved;
  final void Function(String) onRemoveSaved;
  final void Function(int) onRemove;

  const _NamesTab({
    required this.players,
    required this.savedPlayers,
    required this.nameController,
    required this.onAdd,
    required this.onAddSaved,
    required this.onRemoveSaved,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  autofocus: false,
                  decoration: const InputDecoration(hintText: 'اسم اللاعب الجديد'),
                  style: const TextStyle(fontFamily: 'Cairo'),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppTheme.mafiaPrimary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          
          if (savedPlayers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('لاعبون محفوظون (اضغط للإضافة):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: savedPlayers.map((name) {
                  final isAlreadyAdded = players.contains(name);
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onLongPress: () {
                        onRemoveSaved(name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم حذف "$name" من المحفوظات', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.death),
                        );
                      },
                      child: ActionChip(
                        label: Text(name, style: TextStyle(color: isAlreadyAdded ? AppTheme.textSecondary : Colors.white, fontFamily: 'Cairo')),
                        backgroundColor: isAlreadyAdded ? AppTheme.surfaceHigh.withValues(alpha: 0.5) : AppTheme.surface,
                        onPressed: isAlreadyAdded ? null : () => onAddSaved(name),
                        tooltip: 'اضغط مطولاً للحذف',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Players list
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 60, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text('لم يُضَف أي لاعب بعد', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceHigh),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${index + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(players[index], style: const TextStyle(fontSize: 16, fontFamily: 'Cairo')),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.death, size: 20),
                              onPressed: () => onRemove(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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

// ─── Roles Tab ────────────────────────────────────────────────────────────────
class _RolesTab extends StatelessWidget {
  final Map<Role, int> roleConfig;
  final int playerCount;
  final int totalRoles;
  final void Function(Role, int) onChanged;

  const _RolesTab({
    required this.roleConfig,
    required this.playerCount,
    required this.totalRoles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = playerCount - totalRoles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Counter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: remaining == 0 ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي الأدوار: $totalRoles / $playerCount', style: const TextStyle(fontFamily: 'Cairo')),
                Text(
                  remaining > 0 ? 'متبقٍ $remaining' : remaining < 0 ? 'زيادة ${-remaining}' : '✓ مكتمل',
                  style: TextStyle(
                    color: remaining == 0 ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                const _SectionLabel('فريق المافيا'),
                _RoleRow(role: Role.mafiaSheikh,    count: roleConfig[Role.mafiaSheikh]!,    onChanged: onChanged),
                _RoleRow(role: Role.mafiaGirl,       count: roleConfig[Role.mafiaGirl]!,       onChanged: onChanged),
                _RoleRow(role: Role.normalMafia,     count: roleConfig[Role.normalMafia]!,     onChanged: onChanged),
                const SizedBox(height: 8),
                const _SectionLabel('فريق المواطنين'),
                _RoleRow(role: Role.citizensSheikh,  count: roleConfig[Role.citizensSheikh]!,  onChanged: onChanged),
                _RoleRow(role: Role.citizensGirl,    count: roleConfig[Role.citizensGirl]!,    onChanged: onChanged),
                _RoleRow(role: Role.citizensBoy,     count: roleConfig[Role.citizensBoy]!,     onChanged: onChanged),
                _RoleRow(role: Role.goodCitizen,     count: roleConfig[Role.goodCitizen]!,     onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _RoleRow extends StatelessWidget {
  final Role role;
  final int count;
  final void Function(Role, int) onChanged;

  const _RoleRow({required this.role, required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.roleColor(role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? color.withValues(alpha: 0.5) : AppTheme.surfaceHigh,
        ),
      ),
      child: Row(
        children: [
          Icon(AppTheme.roleIcon(role), color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTheme.roleArabicName(role), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                Text(AppTheme.roleAbilityDescription(role), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
          ),
          // Stepper
          Row(
            children: [
              _StepBtn(
                icon: Icons.remove,
                onTap: count > 0 ? () => onChanged(role, count - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? color : AppTheme.textSecondary,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () => onChanged(role, count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap != null ? AppTheme.surfaceHigh : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary),
        ),
      );
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppTheme.mafiaPrimary : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppTheme.mafiaPrimary : AppTheme.surfaceHigh),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}
