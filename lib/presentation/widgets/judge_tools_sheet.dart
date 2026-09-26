import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';

class JudgeToolsSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _JudgeToolsWidget(),
    );
  }
}

class _JudgeToolsWidget extends ConsumerStatefulWidget {
  const _JudgeToolsWidget();

  @override
  ConsumerState<_JudgeToolsWidget> createState() => _JudgeToolsWidgetState();
}

class _JudgeToolsWidgetState extends ConsumerState<_JudgeToolsWidget> {
  int _tabIndex = 0; // 0 for Roles, 1 for Events

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameOrchestratorProvider);
    final presentRoles = state.players.map((p) => p.role).toSet().toList();
    final events = state.eventHistory;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _tabIndex == 0 ? Colors.orangeAccent : Colors.transparent, width: 2)),
                    ),
                    child: Center(
                      child: Text('📖 الأدوار', style: TextStyle(color: _tabIndex == 0 ? Colors.orangeAccent : Colors.white54, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _tabIndex == 1 ? Colors.orangeAccent : Colors.transparent, width: 2)),
                    ),
                    child: Center(
                      child: Text('📜 السجل', style: TextStyle(color: _tabIndex == 1 ? Colors.orangeAccent : Colors.white54, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _tabIndex == 2 ? Colors.orangeAccent : Colors.transparent, width: 2)),
                    ),
                    child: Center(
                      child: Text('👥 الهويات', style: TextStyle(color: _tabIndex == 2 ? Colors.orangeAccent : Colors.white54, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(color: Colors.white10, height: 1, thickness: 1),
          
          // Content
          Expanded(
            child: _tabIndex == 0 
                ? _buildRolesGuide(presentRoles) 
                : _tabIndex == 1 
                    ? _buildEventLog(events, state)
                    : _buildIdentities(state.players, state),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesGuide(List<Role> roles) {
    if (roles.isEmpty) {
      return const Center(child: Text('لم تبدأ اللعبة بعد', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final roleColor = AppTheme.roleColor(role);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withValues(alpha: 0.2),
                backgroundImage: AssetImage(AppTheme.roleImage(role)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTheme.roleArabicName(role), style: TextStyle(color: roleColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(_getRoleDescription(role), style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventLog(List<GameEvent> events, state) {
    if (events.isEmpty) {
      return const Center(child: Text('لم تحدث أي أحداث بعد', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')));
    }
    
    final reversedEvents = events.reversed.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reversedEvents.length,
      itemBuilder: (context, index) {
        final e = reversedEvents[index];
        final actor = e.actorId != null ? state.getPlayerById(e.actorId!) : null;
        final target = e.targetId != null ? state.getPlayerById(e.targetId!) : null;
        
        String desc = 'حدث مجهول';
        IconData icon = Icons.info;
        Color color = Colors.grey;
        
        switch (e.type) {
          case EventType.assassination:
            desc = 'المافيا اغتالت ${target?.name ?? "شخصاً"}';
            icon = Icons.gps_fixed;
            color = Colors.redAccent;
            break;
          case EventType.silence:
            desc = 'السفاح أسكت ${target?.name ?? "شخصاً"}';
            icon = Icons.volume_off;
            color = Colors.purpleAccent;
            break;
          case EventType.investigation:
            desc = 'المحقق فحص ${target?.name ?? "شخصاً"}';
            icon = Icons.search;
            color = Colors.blueAccent;
            break;
          case EventType.protection:
            desc = 'الطبيب حمى ${target?.name ?? "شخصاً"}';
            icon = Icons.health_and_safety;
            color = Colors.greenAccent;
            break;
          case EventType.vote:
            desc = '${actor?.name} صوّت ضد ${target?.name}';
            icon = Icons.how_to_vote;
            color = Colors.orangeAccent;
            break;
          case EventType.elimination:
            desc = 'تم إعدام ${target?.name} (كان ${target != null ? AppTheme.roleArabicName(target.role) : ""})';
            icon = Icons.gavel;
            color = Colors.red;
            break;
          case EventType.citizenBoyRetaliation:
            desc = 'ولد المواطنين ${actor?.name} سحب معه ${target?.name}';
            icon = Icons.flash_on;
            color = Colors.yellow;
            break;
          case EventType.nightResolutionSummary:
            desc = 'نهاية جولة ${e.round}';
            icon = Icons.nights_stay;
            color = Colors.indigoAccent;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(desc, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13)),
              ),
              Text('جولة ${e.round}', style: TextStyle(color: color.withValues(alpha: 0.7), fontFamily: 'Cairo', fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  String _getRoleDescription(Role role) {
    switch (role) {
      case Role.mafiaSheikh: return 'زعيم المافيا. يستيقظ ليلاً لاختيار ضحية واغتيالها. إذا تم فحصه، يظهر كمواطن بريء.';
      case Role.mafiaGirl: return 'بنت المافيا. تستيقظ ليلاً لاختيار شخص وإسكاته، فيُمنع من الكلام في النهار.';
      case Role.normalMafia: return 'عضو بالمافيا. يستيقظ ليلاً مع المافيا ويتشاور معهم لاختيار الضحية.';
      case Role.citizensSheikh: return 'شيخ المواطنين (المحقق). يستيقظ ليلاً ليتفحص شخصاً لمعرفة ما إذا كان من المافيا أم لا.';
      case Role.citizensGirl: return 'بنت المواطنين (الطبيبة). تستيقظ ليلاً لحماية شخص واحد من الاغتيال. يمكنها حماية نفسها.';
      case Role.citizensBoy: return 'الولد الشجاع. إذا تم إقصاؤه (سواء بالتصويت أو الاغتيال)، فإنه يسحب معه لاعباً آخر من اختياره للموت.';
      case Role.goodCitizen: return 'مواطن صالح لا يملك قدرات ليلية. سلاحه الوحيد هو صوته وتحليله في النهار لإسقاط المافيا.';
      case Role.joker: return 'المهرج (الجوكر). دوره مستقل. يفوز باللعبة فوزاً ساحقاً إذا استطاع إقناع الآخرين بالتصويت ضده وإعدامه في النهار!';
    }
  }

  Widget _buildIdentities(List<Player> players, GameState state) {
    if (players.isEmpty) {
      return const Center(child: Text('لا يوجد لاعبين', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')));
    }
    
    final alivePlayers = state.alivePlayers;
    final deadPlayers = players.where((p) => !alivePlayers.contains(p)).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (alivePlayers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, right: 4),
            child: Text('الأحياء', style: TextStyle(color: Colors.greenAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...alivePlayers.map((p) => _buildPlayerIdentityTile(p, true)),
          const SizedBox(height: 16),
        ],
        if (deadPlayers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, right: 4),
            child: Text('الأموات', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...deadPlayers.map((p) => _buildPlayerIdentityTile(p, false)),
        ],
      ],
    );
  }

  Widget _buildPlayerIdentityTile(Player player, bool isAlive) {
    final roleColor = AppTheme.roleColor(player.role);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAlive ? const Color(0xFF1A1A22) : Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAlive ? roleColor.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor.withValues(alpha: 0.2),
            backgroundImage: AssetImage(AppTheme.roleImage(player.role)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name, 
              style: TextStyle(
                color: isAlive ? Colors.white : Colors.white54, 
                fontFamily: 'Cairo', 
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                decoration: isAlive ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Text(AppTheme.roleArabicName(player.role), style: TextStyle(color: roleColor, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
