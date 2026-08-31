class GameException implements Exception {
  final String message;
  final String code;
  
  GameException(this.message, {required this.code});

  @override
  String toString() => 'GameException($code): $message';
}

class InvalidTargetException extends GameException {
  InvalidTargetException(String message) : super(message, code: 'INVALID_TARGET');
}

class ActionAlreadyUsedException extends GameException {
  ActionAlreadyUsedException(String message) : super(message, code: 'ACTION_ALREADY_USED');
}

class PlayerDeadException extends GameException {
  PlayerDeadException(String message) : super(message, code: 'PLAYER_DEAD');
}

class WrongPhaseException extends GameException {
  WrongPhaseException(String message) : super(message, code: 'WRONG_PHASE');
}

class RoleCannotActException extends GameException {
  RoleCannotActException(String message) : super(message, code: 'ROLE_CANNOT_ACT');
}
