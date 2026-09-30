import re

with open('lib/presentation/voting/voting_screen.dart', 'r') as f:
    content = f.read()

old_logic = """                                  Text(voter.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Cairo')),"""

new_logic = """                                  Text(voter.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Cairo')),
                                  if (voter.isCitizenSheikhRevealed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('x3', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/voting/voting_screen.dart', 'w') as f:
    f.write(content)
