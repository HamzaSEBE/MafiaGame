import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  final buildIndex = content.indexOf('Widget build(BuildContext context) {');
  if (buildIndex == -1) {
    print('Could not find build method');
    return;
  }
  
  final startIndex = buildIndex + 'Widget build(BuildContext context) {'.length;
  
  int braceCount = 1;
  int endIndex = -1;
  for (int i = startIndex; i < content.length; i++) {
    if (content[i] == '{') braceCount++;
    if (content[i] == '}') braceCount--;
    if (braceCount == 0) {
      endIndex = i;
      break;
    }
  }
  
  final buildBody = content.substring(startIndex, endIndex);
  
  final newBuildBody = '''
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_stepIndex > 0) {
          _goBack();
        } else {
          final exit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('إنهاء اللعبة؟', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              content: const Text('هل تريد الخروج من اللعبة والعودة للرئيسية؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white))),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (exit == true && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Builder(builder: (context) {
${buildBody}
      }),
    );
  ''';
  
  content = content.replaceRange(startIndex, endIndex, newBuildBody);
  file.writeAsStringSync(content);
}
