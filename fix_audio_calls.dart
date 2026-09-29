import 'dart:io';

void main() {
  final replacements = {
    '.stopMusic()': '.playClick()', // no-op effectively, just a tiny click or we can make it empty
    '.playSuccess()': '.playReveal()',
    '.playNightMusic()': '.playClick()', // no background music, just acknowledge
    '.playGunshot()': '.playKill()',
    '.playHeartbeat()': '.playClick()',
  };

  final files = [
    'lib/presentation/game_over/game_over_screen.dart',
    'lib/presentation/night/night_screen.dart',
    'lib/presentation/night/night_summary_screen.dart',
    'lib/presentation/voting/voting_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('SKIP: $path not found');
      continue;
    }
    var content = file.readAsStringSync();
    var changed = false;

    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
        print('  $path: ${entry.key} -> ${entry.value}');
      }
    }

    // Remove any stopMusic lines entirely (they're no-ops now)
    // Actually let's just replace stopMusic with a no-op method we'll add
    
    if (changed) {
      file.writeAsStringSync(content);
      print('FIXED: $path');
    } else {
      print('OK: $path (no changes needed)');
    }
  }

  print('\nAll files patched!');
}
