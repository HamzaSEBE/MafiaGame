import re

with open('lib/presentation/voting/voting_screen.dart', 'r') as f:
    content = f.read()

# First occurrence
old_1 = """    final voteCounts = <String, int>{};
    for (var target in votes.values) {
      voteCounts[target] = (voteCounts[target] ?? 0) + 1;
    }"""

new_1 = """    final voteCounts = <String, int>{};
    for (var entry in votes.entries) {
      final voterId = entry.key;
      final targetId = entry.value;
      final voterPlayer = ref.read(gameOrchestratorProvider).getPlayerById(voterId);
      final weight = (voterPlayer?.isCitizenSheikhRevealed == true) ? 3 : 1;
      voteCounts[targetId] = (voteCounts[targetId] ?? 0) + weight;
    }"""

content = content.replace(old_1, new_1)

# Second occurrence
old_2 = """    // Calculate votes for each candidate for the badges
    final voteCounts = <String, int>{};
    for (var target in votes.values) {
      voteCounts[target] = (voteCounts[target] ?? 0) + 1;
    }"""

new_2 = """    // Calculate votes for each candidate for the badges
    final voteCounts = <String, int>{};
    for (var entry in votes.entries) {
      final voterId = entry.key;
      final targetId = entry.value;
      final voterPlayer = ref.read(gameOrchestratorProvider).getPlayerById(voterId);
      final weight = (voterPlayer?.isCitizenSheikhRevealed == true) ? 3 : 1;
      voteCounts[targetId] = (voteCounts[targetId] ?? 0) + weight;
    }"""

content = content.replace(old_2, new_2)

with open('lib/presentation/voting/voting_screen.dart', 'w') as f:
    f.write(content)
