import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';

class CinematicRevealScreen extends ConsumerStatefulWidget {
  final String? interactiveSessionId;
  final Future<void> Function()? onInteractiveExit;

  const CinematicRevealScreen({
    super.key,
    this.interactiveSessionId,
    this.onInteractiveExit,
  });

  @override
  ConsumerState<CinematicRevealScreen> createState() =>
      _CinematicRevealScreenState();
}

class _CinematicRevealScreenState extends ConsumerState<CinematicRevealScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    // We delay slightly so state is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequence();
    });
  }

  void _startSequence() async {
    // Play suspense heartbeat sound here if we had one, but we don't have it yet.
    // Let's just wait 2 seconds in silence (suspense)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final state = ref.read(gameOrchestratorProvider);
    final summaryEvent = state.eventHistory.lastWhere(
      (e) => e.type == EventType.nightResolutionSummary,
      orElse: () => GameEvent(
          id: '',
          gameId: '',
          round: state.round,
          phase: state.phase,
          type: EventType.nightResolutionSummary,
          timestamp: DateTime.now()),
    );

    final assassinatedIds =
        (summaryEvent.metadata['assassinatedIds'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
    if (assassinatedIds.isEmpty) {
      // Peaceful
      if (mounted) setState(() => _step = 1); // Peaceful sunrise
      ref.read(audioManagerProvider).playClick();
      await Future.delayed(const Duration(seconds: 3));
    } else {
      // Blood!
      ref.read(audioManagerProvider).playKill();
      if (mounted) {
        setState(() => _step = 2); // Blood flash
        _shakeController.forward(from: 0.0);
      }
      await Future.delayed(const Duration(seconds: 4));
    }

    if (mounted && widget.interactiveSessionId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NightSummaryScreen()),
      );
    } else if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NightSummaryScreen(
            interactiveSessionId: widget.interactiveSessionId,
            onInteractiveExit: widget.onInteractiveExit,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    if (_step == 0) {
      return GamePopScope(
        onExit: widget.onInteractiveExit,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.nightlight_round, color: Colors.white24, size: 80),
                SizedBox(height: 20),
                Text(
                  'المدينة تستيقظ...',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 28,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = ref.watch(gameOrchestratorProvider);
    final summaryEvent = state.eventHistory.lastWhere(
      (e) => e.type == EventType.nightResolutionSummary,
      orElse: () => GameEvent(
          id: '',
          gameId: '',
          round: state.round,
          phase: state.phase,
          type: EventType.nightResolutionSummary,
          timestamp: DateTime.now()),
    );
    final assassinatedIds =
        (summaryEvent.metadata['assassinatedIds'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
    final successfulProtections =
        (summaryEvent.metadata['successfulProtections'] as List<dynamic>?)
                ?.cast<String>() ??
            [];

    if (_step == 1) {
      return GamePopScope(
        onExit: widget.onInteractiveExit,
        child: Scaffold(
          backgroundColor: const Color(0xFFF0F9FF),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wb_sunny,
                    size: 140, color: Colors.orangeAccent),
                const SizedBox(height: 30),
                const Text(
                  'صباح هادئ!',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 10),
                Text(
                  successfulProtections.isNotEmpty
                      ? 'عناية الطبيب أنقذت الضحية هذه الليلة!'
                      : 'لم يُقتل أحد في هذه الليلة.',
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 20,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final deadPlayers = assassinatedIds
        .map((id) => state.getPlayerById(id))
        .whereType<Player>()
        .toList();

    return GamePopScope(
      onExit: widget.onInteractiveExit,
      child: Scaffold(
        backgroundColor: const Color(0xFF450a0a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bloodtype, size: 140, color: Colors.redAccent),
              const SizedBox(height: 30),
              const Text(
                'فاجعة!',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 10),
              const Text(
                'استيقظت المدينة على مقتل:',
                style: TextStyle(
                    color: Colors.white70, fontSize: 22, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 20),
              ...deadPlayers
                  .map((p) => Text(
                        p.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
