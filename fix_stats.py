import re

with open('lib/presentation/stats/stats_screen.dart', 'r') as f:
    content = f.read()

# I will just replace the tail of the build method up to `_buildHeader`
old_tail = """                      );
                    },
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }"""

new_tail = """                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
}"""

if old_tail in content:
    content = content.replace(old_tail, new_tail)
    print("Replaced tail")

with open('lib/presentation/stats/stats_screen.dart', 'w') as f:
    f.write(content)
