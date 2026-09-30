import 'package:mafia_nightfall/domain/enums/role.dart';

class Player {
  final String id;
  final String name;
  final Role role;
  final bool isAlive;
  final bool isSilenced;
  final bool hasSniper;
  final bool isCitizenSheikhRevealed;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    this.isAlive = true,
    this.isSilenced = false,
    this.hasSniper = false,
    this.isCitizenSheikhRevealed = false,
    required this.createdAt,
  });

  Player copyWith({
    String? id,
    String? name,
    Role? role,
    bool? isAlive,
    bool? isSilenced,
    bool? hasSniper,
    bool? isCitizenSheikhRevealed,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      isSilenced: isSilenced ?? this.isSilenced,
      hasSniper: hasSniper ?? this.hasSniper,
      isCitizenSheikhRevealed: isCitizenSheikhRevealed ?? this.isCitizenSheikhRevealed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'isAlive': isAlive,
        'isSilenced': isSilenced,
        'hasSniper': hasSniper,
        'isCitizenSheikhRevealed': isCitizenSheikhRevealed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        role: Role.values.firstWhere((r) => r.name == json['role'], orElse: () => Role.goodCitizen),
        isAlive: json['isAlive'] as bool? ?? true,
        isSilenced: json['isSilenced'] as bool? ?? false,
        hasSniper: json['hasSniper'] as bool? ?? false,
        isCitizenSheikhRevealed: json['isCitizenSheikhRevealed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name, role: $role, isAlive: $isAlive, sniper: $hasSniper, revealed: $isCitizenSheikhRevealed)';
}
