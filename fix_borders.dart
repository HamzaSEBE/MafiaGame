import 'dart:io';
import 'dart:convert';

void main() {
  var file = File(r'c:\Users\Hamza\Documents\Real-Projects\MafiaGameRepo\lib\presentation\night\night_summary_screen.dart');
  var content = file.readAsStringSync(encoding: utf8);
  
  // Replace the border of retaliation dialog
  content = content.replaceFirst(
    'border: Border.all(color: Colors.redAccent, width: 3),',
    'border: Border.all(color: AppTheme.roleColor(target.role), width: 3),'
  );
  
  // Replace the border of assassinated player
  content = content.replaceFirst(
    'border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2),',
    'border: Border.all(color: AppTheme.roleColor(player.role).withValues(alpha: 0.5), width: 2),'
  );
  content = content.replaceFirst(
    'border: Border.all(color: Colors.redAccent, width: 3),',
    'border: Border.all(color: AppTheme.roleColor(player.role), width: 3),'
  );
  
  file.writeAsStringSync(content, encoding: utf8);
  print('Fixed borders in night_summary_screen.dart');
}
