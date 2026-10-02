import re

with open('lib/presentation/voting/voting_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("Image.asset('assets/images/citizens_sheikh.jpg', fit: BoxFit.cover)", "Image.asset(AppTheme.roleImage(Role.citizensSheikh), fit: BoxFit.cover)")

with open('lib/presentation/voting/voting_screen.dart', 'w') as f:
    f.write(content)
