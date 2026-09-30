import re

with open('lib/presentation/setup/role_review_screen.dart', 'r') as f:
    content = f.read()

old_role = """                                  Text(
                                    AppTheme.roleArabicName(p.role),
                                    style: TextStyle(
                                        color: roleColor,
                                        fontFamily: 'Cairo',
                                        fontSize: 11),
                                  ),"""

new_role = """                                  Row(
                                    children: [
                                      Text(
                                        AppTheme.roleArabicName(p.role),
                                        style: TextStyle(
                                            color: roleColor,
                                            fontFamily: 'Cairo',
                                            fontSize: 11),
                                      ),
                                      if (p.hasSniper) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.my_location, color: Colors.amberAccent, size: 12),
                                      ],
                                    ],
                                  ),"""

content = content.replace(old_role, new_role)

with open('lib/presentation/setup/role_review_screen.dart', 'w') as f:
    f.write(content)
