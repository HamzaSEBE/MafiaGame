import 'dart:math';

import 'package:game_core/src/errors/game_error.dart';
import 'package:game_core/src/commands/game_command.dart';
import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/entities/player.dart';
import 'package:game_core/src/rules/game_ruleset.dart';
import 'package:game_core/src/rules/rule_validator.dart';
import 'package:game_core/src/engine/night_resolution_engine.dart';
import 'package:game_core/src/engine/voting_engine.dart';
import 'package:game_core/src/engine/victory_engine.dart';
import 'package:game_core/src/engine/citizen_boy_engine.dart';
import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/enums/role.dart';
import 'package:uuid/uuid.dart';

/// Shared game logic used by the moderator and the authoritative server.
class GameMachine {
  GameMachine(
    this.state, {
    DateTime Function()? clock,
    String Function()? nextId,
  }) : clock = clock ?? DateTime.now,
       nextId = nextId ?? const Uuid().v4;
  GameState state;
  final DateTime Function() clock;
  final String Function() nextId;

  void restoreCheckpoint(GameState checkpoint) {
    if (checkpoint.id.isEmpty ||
        checkpoint.round < 1 ||
        checkpoint.players.length > 200 ||
        checkpoint.players.map((p) => p.id).toSet().length !=
            checkpoint.players.length) {
      throw StateError('حالة اللعبة المحفوظة غير صالحة.');
    }
    state = checkpoint.copyWith(
      players: checkpoint.players,
      eventHistory: checkpoint.eventHistory,
    );
  }

  bool get _isSetup =>
      state.phase == Phase.setup || state.phase == Phase.roleReveal;
  bool get _isNight =>
      state.phase.name.startsWith('night') &&
      state.phase != Phase.nightResolution;

  void addPlayer(String name) {
    if (!_isSetup) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 80 ||
        state.players.any((player) => player.name == trimmed)) {
      return;
    }
    state = state.copyWith(
      players: [
        ...state.players,
        Player(
          id: nextId(),
          name: trimmed,
          role: Role.goodCitizen,
          createdAt: clock(),
        ),
      ],
    );
  }

  void removePlayer(String playerId) {
    if (!_isSetup) return;
    state = state.copyWith(
      players: state.players.where((p) => p.id != playerId).toList(),
    );
  }

  /// Expulsion is an administrative removal, never an execution or a kill.
  void kickPlayer(String playerId) {
    if (_isSetup || state.phase == Phase.winCheck) return;
    final player = state.getPlayerById(playerId);
    if (player == null || player.isKicked) return;
    final pendingNight = _isNight;
    final next = state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(isAlive: false, isKicked: true, isSilenced: false)
                : p,
          )
          .toList(),
      eventHistory: [
        ...state.eventHistory.where(
          (e) =>
              !(pendingNight &&
                  e.round == state.round &&
                  e.phase == state.phase &&
                  (e.actorId == playerId || e.targetId == playerId)),
        ),
        GameEvent(
          id: nextId(),
          gameId: state.id,
          round: state.round,
          phase: state.phase,
          type: EventType.playerKicked,
          targetId: playerId,
          timestamp: clock(),
        ),
      ],
    );
    // Kicking the Citizen Boy does not trigger his death ability.
    final before = state;
    if (before.phase == Phase.triggeredAbility &&
        CitizenBoyEngine.pendingActor(next) == null) {
      final fromNight =
          next.eventHistory.any(
            (e) =>
                e.round == next.round &&
                e.type == EventType.nightResolutionSummary,
          ) &&
          !next.eventHistory.any(
            (e) => e.round == next.round && e.type == EventType.elimination,
          );
      state = _afterDeath(
        next,
        fromNight ? Phase.day : Phase.night,
        checkRetaliation: false,
        advanceRound: !fromNight,
      );
    } else {
      state = _afterDeath(next, state.phase, checkRetaliation: false);
      if (state.phase == before.phase && state.phase == Phase.day) {
        state = state.copyWith(
          discussionDeadlineAt: before.discussionDeadlineAt,
          discussionRemainingSeconds: before.discussionRemainingSeconds,
          discussionPaused: before.discussionPaused,
        );
      }
    }
  }

  void prepareRematch() {
    if (state.phase != Phase.winCheck) {
      throw StateError('يمكن إعادة المباراة بعد ظهور النتيجة فقط.');
    }
    state = GameState(
      id: nextId(),
      rules: state.rules,
      players: [
        for (final p in state.players.where((p) => !p.isKicked))
          p.copyWith(
            isAlive: true,
            isSilenced: false,
            hasSniper: false,
            isCitizenSheikhRevealed: false,
          ),
      ],
    );
  }

  void updatePlayer(Player updatedPlayer) {
    if (!_isSetup) return;
    final name = updatedPlayer.name.trim();
    if (name.isEmpty ||
        name.length > 80 ||
        state.players.any(
          (player) => player.id != updatedPlayer.id && player.name == name,
        )) {
      return;
    }
    final players = state.players
        .map(
          (p) =>
              p.id == updatedPlayer.id ? updatedPlayer.copyWith(name: name) : p,
        )
        .toList();
    state = state.copyWith(players: _ensureSniper(players));
  }

  /// Swap the complete assignment atomically so sniper ownership follows its
  /// citizen role and observers never see an intermediate role distribution.
  void swapPlayerRoles(String firstId, String secondId) {
    if (!_isSetup || firstId == secondId) return;
    final first = state.getPlayerById(firstId);
    final second = state.getPlayerById(secondId);
    if (first == null || second == null) return;
    final players = state.players.map((player) {
      if (player.id == firstId) {
        return player.copyWith(role: second.role, hasSniper: second.hasSniper);
      }
      if (player.id == secondId) {
        return player.copyWith(role: first.role, hasSniper: first.hasSniper);
      }
      return player;
    }).toList();
    state = state.copyWith(players: _ensureSniper(players));
  }

  void shufflePlayers() {
    if (!_isSetup) return;
    state = state.copyWith(
      players: List<Player>.from(state.players)..shuffle(Random.secure()),
    );
  }

  void shuffleAssignedRoles() {
    if (!_isSetup) return;
    final players = List<Player>.from(state.players)..shuffle(Random.secure());
    final roles = players.map((p) => p.role).toList()..shuffle(Random.secure());
    state = state.copyWith(
      players: _ensureSniper([
        for (var i = 0; i < players.length; i++)
          players[i].copyWith(
            role: roles[i],
            hasSniper: false,
            isCitizenSheikhRevealed: false,
          ),
      ]),
    );
  }

  List<Player> _ensureSniper(List<Player> players) {
    final citizens = players
        .where((p) => p.role.team == Team.citizens)
        .toList();
    String? sniperId;
    if (state.rules.abilityRules.sniper && citizens.isNotEmpty) {
      sniperId = citizens.where((p) => p.hasSniper).firstOrNull?.id;
      sniperId ??= (citizens..shuffle(Random.secure())).first.id;
    }
    return players.map((p) => p.copyWith(hasSniper: p.id == sniperId)).toList();
  }

  void updateRules(GameRuleset rules) {
    if (!_isSetup) return;
    state = state.copyWith(rules: rules);
    if (state.phase == Phase.roleReveal) {
      state = state.copyWith(players: _ensureSniper(state.players));
    }
  }

  void citizenSheikhReveal(String playerId) {
    final player = state.getPlayerById(playerId);
    if (!state.rules.abilityRules.citizenSheikhReveal ||
        (state.phase != Phase.day && state.phase != Phase.voting) ||
        player == null ||
        !player.isAlive ||
        player.role != Role.citizensSheikh ||
        player.isCitizenSheikhRevealed) {
      return;
    }
    state = state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(isCitizenSheikhRevealed: true)
                : p,
          )
          .toList(),
      eventHistory: [
        ...state.eventHistory,
        GameEvent(
          id: nextId(),
          gameId: state.id,
          round: state.round,
          phase: state.phase,
          type: EventType.citizenSheikhReveal,
          actorId: playerId,
          timestamp: clock(),
        ),
      ],
    );
  }

  String? assignRoles(Map<Role, int> roleConfig) {
    if (!_isSetup) return 'لا يمكن تغيير الأدوار بعد بدء اللعبة';
    if (roleConfig.values.any((count) => count < 0)) {
      return 'عدد اللاعبين لكل دور يجب ألا يكون سالباً';
    }
    final totalRoles = roleConfig.values.fold(0, (a, b) => a + b);
    if (totalRoles != state.players.length || totalRoles == 0) {
      return 'عدد الأدوار ($totalRoles) لا يساوي عدد اللاعبين (${state.players.length})';
    }
    final roles = [
      for (final entry in roleConfig.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ]..shuffle(Random.secure());
    final initialMafiaCount = roles
        .where((role) => role.team == Team.mafia)
        .length;
    final victoryRules = state.rules.victoryRules;
    if (victoryRules.mode == VictoryMode.exactMafiaExecutions &&
        (victoryRules.requiredCorrectExecutions < 1 ||
            victoryRules.requiredCorrectExecutions > initialMafiaCount)) {
      return 'عدد إعدامات المافيا المطلوبة يجب أن يكون بين 1 وعدد المافيا';
    }
    final players = _ensureSniper([
      for (var i = 0; i < state.players.length; i++)
        state.players[i].copyWith(
          role: roles[i],
          isAlive: true,
          isSilenced: false,
          hasSniper: false,
          isCitizenSheikhRevealed: false,
        ),
    ]);
    state = GameState(
      id: state.id,
      players: players,
      rules: state.rules,
      phase: Phase.roleReveal,
      initialMafiaCount: initialMafiaCount,
    );
    return null;
  }

  void submitNightAction({
    required String actorId,
    required String targetId,
    required EventType type,
  }) {
    final command = switch (type) {
      EventType.assassination => SubmitAssassinationCommand(
        actorId: actorId,
        targetId: targetId,
      ),
      EventType.silence => SubmitSilenceCommand(
        actorId: actorId,
        targetId: targetId,
      ),
      EventType.investigation => SubmitInvestigationCommand(
        actorId: actorId,
        targetId: targetId,
      ),
      EventType.protection => SubmitProtectionCommand(
        actorId: actorId,
        targetId: targetId,
      ),
      EventType.sniperKill => SubmitSniperCommand(
        actorId: actorId,
        targetId: targetId,
      ),
      _ => throw RoleCannotActException('Not a night action'),
    };
    // Replace a retried/edited action before validating lifetime limits. This
    // keeps one action per actor/type/night without consuming a second use.
    final history = state.eventHistory
        .where(
          (event) =>
              !(event.gameId == state.id &&
                  event.round == state.round &&
                  event.phase == Phase.night &&
                  event.actorId == actorId &&
                  event.type == type),
        )
        .toList();
    RuleValidator.validate(command, state.copyWith(eventHistory: history));
    state = state.copyWith(
      eventHistory: [
        ...history,
        GameEvent(
          id: nextId(),
          gameId: state.id,
          round: state.round,
          phase: Phase.night,
          type: type,
          actorId: actorId,
          targetId: targetId,
          timestamp: clock(),
        ),
      ],
    );
  }

  void undoLastNightAction() {
    if (!_isNight || state.eventHistory.isEmpty) return;
    final lastEvent = state.eventHistory.last;
    if (lastEvent.phase == Phase.night && lastEvent.round == state.round) {
      state = state.copyWith(
        eventHistory: List<GameEvent>.from(state.eventHistory)..removeLast(),
      );
    }
  }

  void resolveNight() {
    if (!_isNight && state.phase != Phase.nightResolution) return;
    final nextState = NightResolutionEngine.resolve(
      state,
      state.rules,
      timestamp: clock(),
    );
    state = _afterDeath(nextState, Phase.day);
  }

  void startVoting() {
    if (state.phase == Phase.day) {
      state = state.copyWith(phase: Phase.voting, discussionDeadlineAt: null);
    }
  }

  void beginDay() {
    if (state.phase == Phase.roleReveal) {
      state = state.copyWith(
        phase: Phase.day,
        discussionDeadlineAt: clock().add(const Duration(minutes: 5)),
        discussionPaused: false,
        discussionRemainingSeconds: 300,
      );
    }
  }

  void beginIntroductionNight() {
    if (state.phase == Phase.roleReveal) {
      state = state.copyWith(phase: Phase.night, round: 1);
    }
  }

  void skipIntroductionNight() {
    if (state.phase == Phase.roleReveal ||
        (state.phase == Phase.night && state.round == 1)) {
      state = state.copyWith(
        phase: Phase.day,
        discussionDeadlineAt: clock().add(const Duration(minutes: 5)),
        discussionPaused: false,
        discussionRemainingSeconds: 300,
      );
    }
  }

  void submitFinalVotes(Map<String, String> finalVotes) {
    // The local moderator opens voting directly from the day screen.
    if (state.phase != Phase.day && state.phase != Phase.voting) return;
    final votingState = state.copyWith(phase: Phase.voting);
    for (final entry in finalVotes.entries) {
      RuleValidator.validate(
        SubmitVoteCommand(voterId: entry.key, candidateId: entry.value),
        votingState,
      );
    }
    final history = state.eventHistory
        .where(
          (e) =>
              !(e.gameId == state.id &&
                  e.round == state.round &&
                  e.type == EventType.vote),
        )
        .toList();
    state = votingState.copyWith(
      eventHistory: [
        ...history,
        for (final entry in finalVotes.entries)
          GameEvent(
            id: nextId(),
            gameId: state.id,
            round: state.round,
            phase: Phase.voting,
            type: EventType.vote,
            actorId: entry.key,
            targetId: entry.value,
            timestamp: clock(),
          ),
      ],
    );
  }

  Map<String, dynamic> resolveVote() {
    final resolved = state.eventHistory
        .where(
          (event) =>
              event.gameId == state.id &&
              event.round == state.round &&
              event.type == EventType.elimination,
        )
        .lastOrNull;
    if (resolved != null) {
      return {'isTie': false, 'eliminatedId': resolved.targetId};
    }
    if (state.phase != Phase.voting && state.phase != Phase.voteResolution) {
      return {'isTie': false, 'eliminatedId': null};
    }
    final result = VotingEngine.calculateVotes(state);
    if (result.isTie) {
      return {'isTie': true, 'tiedPlayers': result.tiedPlayerIds};
    }
    final eliminatedId = result.eliminatedPlayerId;
    if (eliminatedId != null) {
      state = _afterDeath(
        VotingEngine.applyElimination(state, eliminatedId, timestamp: clock()),
        Phase.elimination,
      );
    }
    return {'isTie': false, 'eliminatedId': eliminatedId};
  }

  void skipElimination() => advanceToNight();

  void revote() {
    if (state.phase != Phase.day && state.phase != Phase.voting) return;
    state = state.copyWith(
      phase: Phase.voting,
      eventHistory: state.eventHistory
          .where(
            (event) =>
                !(event.gameId == state.id &&
                    event.round == state.round &&
                    event.type == EventType.vote),
          )
          .toList(),
    );
  }

  void citizenBoyRetaliation({
    required String actorId,
    required String targetId,
    required Phase nextPhase,
  }) {
    if (state.phase != Phase.triggeredAbility) return;
    final pending = CitizenBoyEngine.pendingActor(state);
    if (pending?.id != actorId) return;
    final nextState = CitizenBoyEngine.applyRetaliation(
      state,
      actorId,
      targetId,
      timestamp: clock(),
    );
    if (identical(nextState, state)) return;
    state = _afterDeath(
      nextState,
      nextPhase,
      advanceRound: nextPhase == Phase.night,
    );
  }

  void skipTriggeredAbility(Phase nextPhase) {
    if (state.phase != Phase.triggeredAbility) return;
    state = _afterDeath(
      state,
      nextPhase,
      checkRetaliation: false,
      advanceRound: nextPhase == Phase.night,
    );
  }

  void advanceToNight() {
    if (state.phase == Phase.triggeredAbility) {
      skipTriggeredAbility(Phase.night);
    } else if (state.phase == Phase.day ||
        state.phase == Phase.voting ||
        state.phase == Phase.elimination) {
      state = state.copyWith(phase: Phase.night, round: state.round + 1);
    }
  }

  /// Retaliation is resolved before declaring a faction winner. Otherwise a
  /// Citizen Boy killed at parity loses his documented final action.
  GameState _afterDeath(
    GameState nextState,
    Phase nextPhase, {
    bool checkRetaliation = true,
    bool advanceRound = false,
  }) {
    if (checkRetaliation &&
        nextState.alivePlayers.isNotEmpty &&
        CitizenBoyEngine.pendingActor(nextState) != null) {
      return nextState.copyWith(phase: Phase.triggeredAbility);
    }
    final status = VictoryEngine.evaluate(nextState);
    if (status != VictoryStatus.continueGame) {
      final winner = switch (status) {
        VictoryStatus.mafiaWin => Team.mafia,
        VictoryStatus.jokerWin => Team.independent,
        _ => Team.citizens,
      };
      final mode = nextState.rules.victoryRules.mode;
      final reason = switch (winner) {
        Team.independent => 'إقصاء الجوكر بالتصويت',
        Team.mafia when mode == VictoryMode.equalCount =>
          'التعادل مع العدد الأصلي للمافيا',
        Team.mafia when mode == VictoryMode.classic =>
          nextState.alivePlayers
                      .where((p) => p.role.team == Team.mafia)
                      .length ==
                  nextState.alivePlayers
                      .where((p) => p.role.team == Team.citizens)
                      .length
              ? 'تعادل الأحياء دون اجتماع قنص غير مستخدم وحماية متاحة للمواطنين'
              : 'تفوق عدد المافيا الأحياء على المواطنين الأحياء',
        Team.mafia => 'استحالة فوز المواطنين',
        Team.citizens when mode == VictoryMode.exactMafiaExecutions =>
          'إعدامات صحيحة للمافيا',
        Team.citizens => 'القضاء التام على المافيا',
      };
      return nextState.copyWith(
        phase: Phase.winCheck,
        winner: winner,
        victoryReason: reason,
      );
    }
    return nextState.copyWith(
      discussionDeadlineAt: nextPhase == Phase.day
          ? clock().add(const Duration(minutes: 5))
          : null,
      discussionRemainingSeconds: 300,
      discussionPaused: false,
      phase: nextPhase,
      round: nextState.round + (advanceRound ? 1 : 0),
    );
  }

  void updateDiscussionClock(int remainingSeconds, {required bool paused}) {
    if (state.phase != Phase.day ||
        remainingSeconds < 0 ||
        remainingSeconds > 7200) {
      throw StateError('Invalid discussion clock');
    }
    state = state.copyWith(
      discussionDeadlineAt: paused
          ? null
          : clock().add(Duration(seconds: remainingSeconds)),
      discussionRemainingSeconds: remainingSeconds,
      discussionPaused: paused,
    );
  }

  void resetGame() {
    final players = state.players
        .where((p) => !p.isKicked)
        .map(
          (p) => p.copyWith(
            role: Role.goodCitizen,
            isAlive: true,
            isSilenced: false,
            hasSniper: false,
            isCitizenSheikhRevealed: false,
          ),
        )
        .toList();
    state = GameState(id: nextId(), players: players, rules: state.rules);
  }
}
