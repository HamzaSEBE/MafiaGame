import re

with open('lib/presentation/setup/setup_screen.dart', 'r') as f:
    content = f.read()

new_validation = """    if (_totalRoles != players.length) {
      _showError('عدد الأدوار ($_totalRoles) لا يساوي عدد اللاعبين (${players.length})');
      return;
    }
    
    final mafiaCount = _roleConfig[Role.mafiaSheikh]! + _roleConfig[Role.mafiaGirl]! + _roleConfig[Role.normalMafia]!;
    final citizenCount = _roleConfig[Role.citizensSheikh]! + _roleConfig[Role.citizensGirl]! + _roleConfig[Role.citizensBoy]! + _roleConfig[Role.goodCitizen]!;
    
    if (mafiaCount == 0) {
      _showError('يجب إضافة مافيا واحدة على الأقل لبدء اللعبة!');
      return;
    }
    if (citizenCount == 0) {
      _showError('يجب إضافة مواطن واحد على الأقل لبدء اللعبة!');
      return;
    }"""

content = content.replace("""    if (_totalRoles != players.length) {
      _showError('عدد الأدوار ($_totalRoles) لا يساوي عدد اللاعبين (${players.length})');
      return;
    }""", new_validation)

with open('lib/presentation/setup/setup_screen.dart', 'w') as f:
    f.write(content)
