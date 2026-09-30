import re

with open('lib/domain/entities/interactive/models.dart', 'r') as f:
    content = f.read()

# Add globalAnnouncement to InteractiveSession
old_session = """  final Team? winner;
  final DateTime createdAt;

  InteractiveSession({"""

new_session = """  final Team? winner;
  final DateTime createdAt;
  final String? globalAnnouncement;

  InteractiveSession({"""

content = content.replace(old_session, new_session)

old_session_cons = """    this.actionsRound,
    this.winner,
    required this.createdAt,
  });"""

new_session_cons = """    this.actionsRound,
    this.winner,
    required this.createdAt,
    this.globalAnnouncement,
  });"""

content = content.replace(old_session_cons, new_session_cons)

old_session_tojson = """        'winner': winner?.name,
        'createdAt': createdAt.toIso8601String(),
      };"""

new_session_tojson = """        'winner': winner?.name,
        'createdAt': createdAt.toIso8601String(),
        'globalAnnouncement': globalAnnouncement,
      };"""

content = content.replace(old_session_tojson, new_session_tojson)

old_session_fromjson = """        winner: json['winner'] != null
            ? Team.values.firstWhere((e) => e.name == json['winner'])
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );"""

new_session_fromjson = """        winner: json['winner'] != null
            ? Team.values.firstWhere((e) => e.name == json['winner'])
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        globalAnnouncement: json['globalAnnouncement'] as String?,
      );"""

content = content.replace(old_session_fromjson, new_session_fromjson)

# Add isCitizenSheikhRevealed to InteractiveSeat
old_seat = """  final bool isAlive;
  final SeatStatus status;
  final String? linkedUid;

  InteractiveSeat({"""

new_seat = """  final bool isAlive;
  final SeatStatus status;
  final String? linkedUid;
  final bool isCitizenSheikhRevealed;

  InteractiveSeat({"""

content = content.replace(old_seat, new_seat)

old_seat_cons = """    required this.isAlive,
    required this.status,
    this.linkedUid,
  });"""

new_seat_cons = """    required this.isAlive,
    required this.status,
    this.linkedUid,
    this.isCitizenSheikhRevealed = false,
  });"""

content = content.replace(old_seat_cons, new_seat_cons)

old_seat_tojson = """        'isAlive': isAlive,
        'status': status.name,
        'linkedUid': linkedUid,
      };"""

new_seat_tojson = """        'isAlive': isAlive,
        'status': status.name,
        'linkedUid': linkedUid,
        'isCitizenSheikhRevealed': isCitizenSheikhRevealed,
      };"""

content = content.replace(old_seat_tojson, new_seat_tojson)

old_seat_fromjson = """        status: SeatStatus.values.firstWhere((e) => e.name == json['status'],
            orElse: () => SeatStatus.unlinked),
        linkedUid: json['linkedUid'] as String?,
      );"""

new_seat_fromjson = """        status: SeatStatus.values.firstWhere((e) => e.name == json['status'],
            orElse: () => SeatStatus.unlinked),
        linkedUid: json['linkedUid'] as String?,
        isCitizenSheikhRevealed: json['isCitizenSheikhRevealed'] as bool? ?? false,
      );"""

content = content.replace(old_seat_fromjson, new_seat_fromjson)

with open('lib/domain/entities/interactive/models.dart', 'w') as f:
    f.write(content)
