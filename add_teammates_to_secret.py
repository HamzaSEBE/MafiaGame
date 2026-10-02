import re

with open('lib/domain/entities/interactive/models.dart', 'r') as f:
    content = f.read()

# Add mafiaTeammates to properties
content = content.replace(
    "final bool isSniper;",
    "final bool isSniper;\n  final List<String> mafiaTeammates;"
)

# Add to constructor
content = content.replace(
    "this.isSniper = false,\n  });",
    "this.isSniper = false,\n    this.mafiaTeammates = const [],\n  });"
)

# Add to toJson
content = content.replace(
    "'isSniper': isSniper,\n      };",
    "'isSniper': isSniper,\n        'mafiaTeammates': mafiaTeammates,\n      };"
)

# Add to fromJson
content = content.replace(
    "isSniper: json['isSniper'] as bool? ?? false,\n    );",
    "isSniper: json['isSniper'] as bool? ?? false,\n      mafiaTeammates: (json['mafiaTeammates'] as List? ?? const []).cast<String>(),\n    );"
)

with open('lib/domain/entities/interactive/models.dart', 'w') as f:
    f.write(content)
