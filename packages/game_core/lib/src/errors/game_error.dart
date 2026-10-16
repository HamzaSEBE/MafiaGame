class GameException implements Exception {
  final String message;
  final String code;

  GameException(this.message, {required this.code});

  @override
  String toString() => 'GameException($code): $message';
}

class InvalidTargetException extends GameException {
  InvalidTargetException(super.message) : super(code: 'INVALID_TARGET');
}

class ActionAlreadyUsedException extends GameException {
  ActionAlreadyUsedException(super.message)
    : super(code: 'ACTION_ALREADY_USED');
}

class PlayerDeadException extends GameException {
  PlayerDeadException(super.message) : super(code: 'PLAYER_DEAD');
}

class WrongPhaseException extends GameException {
  WrongPhaseException(super.message) : super(code: 'WRONG_PHASE');
}

class RoleCannotActException extends GameException {
  RoleCannotActException(super.message) : super(code: 'ROLE_CANNOT_ACT');
}
