import 'package:game_core/src/commands/game_command.dart';
import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/entities/player.dart';
import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/enums/role.dart';
import 'package:game_core/src/errors/game_error.dart';
import 'package:game_core/src/events/game_event.dart';

class RuleValidator {
  static void validate(GameCommand command, GameState state) {
    switch (command) {
      case AddPlayerCommand():
      case RemovePlayerCommand():
      case AssignRoleCommand():
      case NextPhaseCommand():
        break;

      case StartGameCommand():
        if (state.phase != Phase.setup) {
          throw WrongPhaseException("Game already started");
        }
        if (state.players.length < 5) {
          throw GameException(
            "Need at least 5 players",
            code: "NOT_ENOUGH_PLAYERS",
          );
        }

      case SubmitAssassinationCommand(:final actorId, :final targetId):
        _requireNight(state);
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (!actor.isAlive) throw PlayerDeadException("Actor is dead");
        if (actor.role.team != Team.mafia) {
          throw RoleCannotActException("Actor is not Mafia");
        }
        if (!target.isAlive) {
          throw InvalidTargetException("Cannot assassinate a dead player");
        }
        if (target.role.team == Team.mafia) {
          throw InvalidTargetException("Cannot assassinate a mafia member");
        }
        if (actor.id == target.id) {
          throw InvalidTargetException("Cannot assassinate self");
        }

      case SubmitSilenceCommand(:final actorId, :final targetId):
        _requireNight(state);
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (!actor.isAlive) throw PlayerDeadException("Mafia Girl is dead");
        if (actor.role != Role.mafiaGirl) {
          throw RoleCannotActException("Actor is not Mafia Girl");
        }
        if (!target.isAlive) {
          throw InvalidTargetException("Cannot silence a dead player");
        }
        final pastSilences = state.eventHistory.where(
          (e) =>
              e.gameId == state.id &&
              e.type == EventType.silence &&
              e.actorId == actor.id &&
              e.targetId == target.id,
        );
        final limit = state.rules.abilityRules.silenceTargetLimit;
        if (limit != -1 && pastSilences.length >= limit) {
          throw ActionAlreadyUsedException("Silence target limit reached");
        }

      case SubmitInvestigationCommand(:final actorId, :final targetId):
        _requireNight(state);
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (!actor.isAlive) throw PlayerDeadException("Citizen Sheikh is dead");
        if (actor.role != Role.citizensSheikh) {
          throw RoleCannotActException("Actor is not Citizen Sheikh");
        }
        if (!target.isAlive) {
          throw InvalidTargetException("Cannot investigate a dead player");
        }
        if (actor.id == target.id) {
          throw InvalidTargetException("Cannot investigate self");
        }

      case SubmitProtectionCommand(:final actorId, :final targetId):
        _requireNight(state);
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (!actor.isAlive) throw PlayerDeadException("Citizen Girl is dead");
        if (actor.role != Role.citizensGirl) {
          throw RoleCannotActException("Actor is not Citizen Girl");
        }
        if (!target.isAlive) {
          throw InvalidTargetException("Cannot protect a dead player");
        }
        final pastProtections = state.eventHistory.where(
          (e) =>
              e.gameId == state.id &&
              e.type == EventType.protection &&
              e.actorId == actor.id &&
              e.targetId == target.id,
        );
        final limit = state.rules.abilityRules.protectionTargetLimit;
        if (limit != -1 && pastProtections.length >= limit) {
          throw ActionAlreadyUsedException("Protection target limit reached");
        }

      case SubmitSniperCommand(:final actorId, :final targetId):
        _requireNight(state);
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (!actor.isAlive) throw PlayerDeadException('Sniper is dead');
        if (!state.rules.abilityRules.sniper ||
            !actor.hasSniper ||
            actor.role.team != Team.citizens) {
          throw RoleCannotActException(
            'Actor is not an enabled citizen sniper',
          );
        }
        if (!target.isAlive || actor.id == target.id) {
          throw InvalidTargetException('Sniper requires another living target');
        }
        if (state.eventHistory.any(
          (event) =>
              event.gameId == state.id &&
              event.type == EventType.sniperKill &&
              event.actorId == actor.id,
        )) {
          throw ActionAlreadyUsedException('Sniper has already fired');
        }

      case ResolveNightCommand():
        break; // We skip phase check in night screen flow

      case StartVotingCommand():
        break;

      case SubmitVoteCommand(:final voterId, :final candidateId):
        if (state.phase != Phase.voting) {
          throw WrongPhaseException("Not Voting phase");
        }
        final voter = _getPlayer(state, voterId);
        final candidate = _getPlayer(state, candidateId);
        if (!voter.isAlive) {
          throw PlayerDeadException("Dead players cannot vote");
        }
        if (!candidate.isAlive) {
          throw InvalidTargetException("Cannot vote for a dead player");
        }
        if (voter.id == candidate.id) {
          throw InvalidTargetException("Cannot vote for yourself");
        }

      case ResolveVoteCommand():
        break;

      case SkipEliminationCommand():
        break;

      case RevoteCommand():
        break;

      case TriggerCitizenBoyCommand(:final actorId, :final targetId):
        if (state.phase != Phase.triggeredAbility) {
          throw WrongPhaseException("Not in triggered ability phase");
        }
        final actor = _getPlayer(state, actorId);
        final target = _getPlayer(state, targetId);
        if (actor.role != Role.citizensBoy) {
          throw RoleCannotActException("Only Citizen Boy can use this ability");
        }
        if (actor.isAlive) {
          throw RoleCannotActException('Citizen Boy is still alive');
        }
        if (!target.isAlive) {
          throw InvalidTargetException("Cannot take a dead player");
        }
        if (actor.id == target.id) {
          throw InvalidTargetException("Cannot target self");
        }
        if (state.eventHistory.any(
          (event) =>
              event.gameId == state.id &&
              event.type == EventType.citizenBoyRetaliation &&
              event.actorId == actor.id,
        )) {
          throw ActionAlreadyUsedException('Citizen Boy already retaliated');
        }
    }
  }

  static void _requireNight(GameState state) {
    if (!state.phase.name.startsWith('night') ||
        state.phase == Phase.nightResolution) {
      throw WrongPhaseException('Not an active night phase');
    }
  }

  static Player _getPlayer(GameState state, String id) {
    final player = state.getPlayerById(id);
    if (player == null) {
      throw GameException("Player not found", code: "PLAYER_NOT_FOUND");
    }
    return player;
  }
}
