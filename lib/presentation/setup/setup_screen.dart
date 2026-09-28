import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/data/repositories/player_profiles_repository.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_lobby_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  int _currentTab = 0; // 0 = players, 1 = roles
  
  List<String> _savedPlayers = [];
  final PlayerProfilesRepository _profilesRepo = PlayerProfilesRepository();

  final Map<Role, int> _roleConfig = {
    Role.mafiaSheikh:    0,
    Role.mafiaGirl:      0,
    Role.normalMafia:    0,
    Role.citizensSheikh: 0,
    Role.citizensGirl:   0,
    Role.citizensBoy:    0,
    Role.goodCitizen:    0,
    Role.joker:          0,
  };

  int get _totalRoles => _roleConfig.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }
  
  Future<void> _loadProfiles() async {
    final profiles = await _profilesRepo.loadSavedPlayers();
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
      _profilesRepo.savePlayers(_savedPlayers);
    }
  }

  void _confirmDeleteSavedPlayer(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف اللاعب المحفوظ؟', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: Text('هل تريد حذف "$name" من القائمة المحفوظة؟', style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _savedPlayers.remove(name));
              _profilesRepo.savePlayers(_savedPlayers);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
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
      _showError('عدد الأدوار ($_totalRoles) لا يساوي عدد اللاعبين (${players.length})');
      return;
    }

    // Save player names for next game
    final playerNames = players.map((p) => p.name).toList();
    _profilesRepo.savePlayers(playerNames);

    // Shuffle the player order for fully random reveal sequence
    ref.read(gameOrchestratorProvider.notifier).shufflePlayers();

    final error = ref.read(gameOrchestratorProvider.notifier).assignRoles(_roleConfig);
    if (error != null) {
      _showError(error);
      return;
    }
    
    if (isInteractive) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const JudgeLobbyScreen()));
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(gameOrchestratorProvider).players;

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      body: Stack(
        children: [
          // Elegant Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.8),
                  radius: 1.5,
                  colors: [Color(0xFF261D15), Color(0xFF100C09), Color(0xFF07070B)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orangeAccent),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'تجهيز المعركة',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 10)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                          onChanged: (r, c) => setState(() => _roleConfig[r] = c),
                          onAutoDistribute: _autoDistributeRoles,
                        ),
                  ),
                ),
                
                // Start Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: (players.length >= 4 && _totalRoles == players.length)
                                  ? [const Color(0xFFDD2476), const Color(0xFF900C3F)]
                                  : [Colors.grey.shade800, Colors.grey.shade900],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: (players.length >= 4 && _totalRoles == players.length) 
                                  ? () => _startGame(false) 
                                  : () {
                                     if (players.length < 4) _showError('يجب إضافة 4 لاعبين على الأقل');
                                     else _showError('عدد الأدوار لا يطابق عدد اللاعبين');
                                  },
                              child: const Center(
                                child: Text('جهاز واحد',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: (players.length >= 4 && _totalRoles == players.length)
                                  ? [const Color(0xFFFF512F), const Color(0xFFF09819)]
                                  : [Colors.grey.shade800, Colors.grey.shade900],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (players.length >= 4 && _totalRoles == players.length)
                                ? [const BoxShadow(color: Color(0xFFFF512F), blurRadius: 10, spreadRadius: 1)]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: (players.length >= 4 && _totalRoles == players.length) 
                                  ? () => _startGame(true) 
                                  : () {
                                     if (players.length < 4) _showError('يجب إضافة 4 لاعبين على الأقل');
                                     else _showError('عدد الأدوار لا يطابق عدد اللاعبين');
                                  },
                              child: const Center(
                                child: Text('لعب تفاعلي 🌐',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
  const _TabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.orangeAccent : Colors.white54),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.orangeAccent : Colors.white54,
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
                    style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم اللاعب...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontFamily: 'Cairo'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: onAdd,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: () => onAdd(nameController.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Saved Players
          if (savedPlayers.isNotEmpty) ...[
            Text('اللاعبون المحفوظون:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'Cairo')),
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
                            backgroundColor: isAdded ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(color: isAdded ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.1)),
                            label: Text(sp, style: TextStyle(color: isAdded ? Colors.orangeAccent : Colors.white70, fontFamily: 'Cairo', fontWeight: isAdded ? FontWeight.bold : FontWeight.normal)),
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(players[index].name, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 18)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
              color: remaining == 0 ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: remaining == 0 ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('الأدوار الموزعة:', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
                      const SizedBox(width: 8),
                      if (playerCount > 0)
                        ElevatedButton.icon(
                          onPressed: onAutoDistribute,
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
                          label: const Text('توزيع ذكي', style: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: const Size(0, 30),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$totalRoles / $playerCount',
                  style: TextStyle(
                    color: remaining == 0 ? Colors.greenAccent : Colors.orangeAccent,
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
                  child: Text('فريق المافيا', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
                _buildRoleRow(Role.mafiaSheikh),
                _buildRoleRow(Role.mafiaGirl),
                _buildRoleRow(Role.normalMafia),
                const Divider(color: Colors.white10, height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('فريق المواطنين', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
                _buildRoleRow(Role.citizensSheikh),
                _buildRoleRow(Role.citizensGirl),
                _buildRoleRow(Role.citizensBoy),
                _buildRoleRow(Role.goodCitizen),
                const Divider(color: Colors.white10, height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('المستقلين', style: TextStyle(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
                _buildRoleRow(Role.joker),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(Role role) {
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
        color: count > 0 ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: count > 0 ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTheme.roleArabicName(role), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                Text(AppTheme.roleAbilityDescription(role), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontFamily: 'Cairo')),
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
                  onPressed: count > 0 ? () => onChanged(role, count - 1) : null,
                ),
                Text('$count', style: TextStyle(color: count > 0 ? color : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
