import 'package:mafia_nightfall/domain/enums/role.dart';

/// Game commands — plain sealed class, no code gen needed.
sealed class GameCommand {
  const GameCommand();
}

// Setup & Start
class AddPlayerCommand extends GameCommand {
  final String name;
  const AddPlayerCommand({required this.name});
}

class RemovePlayerCommand extends GameCommand {
  final String playerId;
  const RemovePlayerCommand({required this.playerId});
}

class AssignRoleCommand extends GameCommand {
  final String playerId;
  final Role role;
  const AssignRoleCommand({required this.playerId, required this.role});
}

class StartGameCommand extends GameCommand {
  const StartGameCommand();
}

// Transitions
class NextPhaseCommand extends GameCommand {
  const NextPhaseCommand();
}

// Night Actions
class SubmitAssassinationCommand extends GameCommand {
  final String actorId;
  final String targetId;
  const SubmitAssassinationCommand({required this.actorId, required this.targetId});
}

class SubmitSilenceCommand extends GameCommand {
  final String actorId;
  final String targetId;
  const SubmitSilenceCommand({required this.actorId, required this.targetId});
}

class SubmitInvestigationCommand extends GameCommand {
  final String actorId;
  final String targetId;
  const SubmitInvestigationCommand({required this.actorId, required this.targetId});
}

class SubmitProtectionCommand extends GameCommand {
  final String actorId;
  final String targetId;
  const SubmitProtectionCommand({required this.actorId, required this.targetId});
}

// Resolutions
class ResolveNightCommand extends GameCommand {
  const ResolveNightCommand();
}

// Day / Voting
class StartVotingCommand extends GameCommand {
  const StartVotingCommand();
}

class SubmitVoteCommand extends GameCommand {
  final String voterId;
  final String candidateId;
  const SubmitVoteCommand({required this.voterId, required this.candidateId});
}

class ResolveVoteCommand extends GameCommand {
  const ResolveVoteCommand();
}

class SkipEliminationCommand extends GameCommand {
  const SkipEliminationCommand();
}

class RevoteCommand extends GameCommand {
  const RevoteCommand();
}

// Special
class TriggerCitizenBoyCommand extends GameCommand {
  final String actorId;
  final String targetId;
  const TriggerCitizenBoyCommand({required this.actorId, required this.targetId});
}
