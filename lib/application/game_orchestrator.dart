import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/game_recovery.dart';
import 'package:mafia_nightfall/data/repositories/checkpoints/local_checkpoint_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:uuid/uuid.dart';

final gameClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final gameOrchestratorProvider = NotifierProvider<GameOrchestrator, GameState>(
  GameOrchestrator.new,
);

/// Riverpod adapter only. All game decisions belong to the shared Dart core.
class GameOrchestrator extends Notifier<GameState> {
  @override
  GameState build() => GameState(id: const Uuid().v4());
  T _change<T>(T Function(GameMachine) operation) {
    final machine = GameMachine(state, clock: ref.read(gameClockProvider));
    final result = operation(machine);
    state = machine.state;
    return result;
  }

  void restoreCheckpoint(GameState state) =>
      _change((g) => g.restoreCheckpoint(state));
  void addPlayer(String name) => _change((g) => g.addPlayer(name));
  void removePlayer(String id) => _change((g) => g.removePlayer(id));
  void updatePlayer(Player player) => _change((g) => g.updatePlayer(player));
  void swapPlayerRoles(String first, String second) =>
      _change((g) => g.swapPlayerRoles(first, second));
  void shufflePlayers() => _change((g) => g.shufflePlayers());
  void shuffleAssignedRoles() => _change((g) => g.shuffleAssignedRoles());
  void updateRules(GameRuleset rules) => _change((g) => g.updateRules(rules));
  void citizenSheikhReveal(String id) =>
      _change((g) => g.citizenSheikhReveal(id));
  String? assignRoles(Map<Role, int> config) =>
      _change((g) => g.assignRoles(config));
  void submitNightAction({
    required String actorId,
    required String targetId,
    required EventType type,
  }) => _change(
    (g) =>
        g.submitNightAction(actorId: actorId, targetId: targetId, type: type),
  );
  void undoLastNightAction() => _change((g) => g.undoLastNightAction());
  void resolveNight() => _change((g) => g.resolveNight());
  void startVoting() => _change((g) => g.startVoting());
  void beginDay() => _change((g) => g.beginDay());
  void beginIntroductionNight() => _change((g) => g.beginIntroductionNight());
  void skipIntroductionNight() => _change((g) => g.skipIntroductionNight());
  void submitFinalVotes(Map<String, String> votes) =>
      _change((g) => g.submitFinalVotes(votes));
  Map<String, dynamic> resolveVote() => _change((g) => g.resolveVote());
  void skipElimination() => _change((g) => g.skipElimination());
  void revote() => _change((g) => g.revote());
  void citizenBoyRetaliation({
    required String actorId,
    required String targetId,
    required Phase nextPhase,
  }) => _change(
    (g) => g.citizenBoyRetaliation(
      actorId: actorId,
      targetId: targetId,
      nextPhase: nextPhase,
    ),
  );
  void skipTriggeredAbility(Phase phase) =>
      _change((g) => g.skipTriggeredAbility(phase));
  void advanceToNight() => _change((g) => g.advanceToNight());
  void updateDiscussionClock(int seconds, {required bool paused}) =>
      _change((g) => g.updateDiscussionClock(seconds, paused: paused));
  void resetGame() => _change((g) => g.resetGame());

  Future<void> endGame() async {
    final gameId = state.id;
    final uid = ref.read(accountIdProvider);
    if (uid != null) {
      await ref.read(localCheckpointRepositoryProvider).clear(uid, gameId);
    }
    resetGame();
    ref.invalidate(gameRecoveryProvider);
  }
}
