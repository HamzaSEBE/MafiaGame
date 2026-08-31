import 'package:mafia_nightfall/domain/enums/role.dart';

class Player {
  final String id;
  final String name;
  final Role role;
  final bool isAlive;
  final bool isSilenced;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    this.isAlive = true,
    this.isSilenced = false,
    required this.createdAt,
  });

  Player copyWith({
    String? id,
    String? name,
    Role? role,
    bool? isAlive,
    bool? isSilenced,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      isSilenced: isSilenced ?? this.isSilenced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name, role: $role, isAlive: $isAlive)';
}
