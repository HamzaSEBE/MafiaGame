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
  // Bounded immutable snapshots share their unchanged lists. Clock updates are
  // excluded so a moderator step always means a game decision, not a timer tick.
  final List<GameState> _undo = [];
  GameState? _groupStart;
  void beginModeratorStep() => _groupStart ??= state;
  void commitModeratorStep() {
    final before = _groupStart;
    _groupStart = null;
    if (before != null && !identical(before, state)) {
      _undo.add(before);
      if (_undo.length > 40) _undo.removeAt(0);
    }
  }

  void cancelModeratorStep() => _groupStart = null;
  bool get canUndo => _undo.isNotEmpty && state.phase != Phase.winCheck;
  T _change<T>(T Function(GameMachine) operation, {bool recordUndo = true}) {
    final before = state;
    final machine = GameMachine(state, clock: ref.read(gameClockProvider));
    final result = operation(machine);
    if (recordUndo &&
        _groupStart == null &&
        !identical(before, machine.state) &&
        before.phase != Phase.setup &&
        (before.phase != Phase.roleReveal ||
            machine.state.phase != Phase.roleReveal)) {
      _undo.add(before);
      if (_undo.length > 40) _undo.removeAt(0);
    }
    state = machine.state;
    return result;
  }

  void restoreCheckpoint(GameState checkpoint) {
    if (checkpoint.id != state.id) _undo.clear();
    final rollback = _undo.indexWhere((s) => identical(s, checkpoint));
    if (rollback >= 0) _undo.removeRange(rollback, _undo.length);
    _change((g) => g.restoreCheckpoint(checkpoint), recordUndo: false);
  }

  GameState undoStep() {
    if (!canUndo) throw StateError('لا توجد خطوة سابقة متاحة.');
    var previous = _undo.removeLast();
    if (previous.phase == Phase.day) {
      final remaining =
          previous.discussionDeadlineAt
              ?.difference(ref.read(gameClockProvider)())
              .inSeconds ??
          previous.discussionRemainingSeconds;
      previous = previous.copyWith(
        discussionDeadlineAt: null,
        discussionRemainingSeconds: remaining.clamp(0, 7200),
        discussionPaused: true,
      );
    }
    state = previous;
    return state;
  }

  void returnUndoAfterFailedWrite(GameState target) {
    _undo.add(target);
    if (_undo.length > 40) _undo.removeAt(0);
  }

  void kickPlayer(String id) => _change((g) => g.kickPlayer(id));
  void prepareRematch() {
    _change((g) => g.prepareRematch(), recordUndo: false);
    _undo.clear();
  }

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
  void updateDiscussionClock(int seconds, {required bool paused}) => _change(
    (g) => g.updateDiscussionClock(seconds, paused: paused),
    recordUndo: false,
  );
  void resetGame() {
    _undo.clear();
    _change((g) => g.resetGame(), recordUndo: false);
  }

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
