import 'dart:io';

void main() {
  final file = File('lib/presentation/setup/setup_screen.dart');
  String content = file.readAsStringSync();

  // Add parameter
  if (!content.contains('final bool isInteractive;')) {
    content = content.replaceFirst(
      'const SetupScreen({super.key});',
      'final bool isInteractive;\n  const SetupScreen({super.key, required this.isInteractive});'
    );
  }

  // Remove the old row of Start Buttons and replace with a single button
  final startStr = '''
                // Start Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
''';
  final endStr = '''
                    ],
                  ),
                ),
''';
  final startIndex = content.indexOf(startStr);
  final endIndex = content.indexOf(endStr, startIndex);

  if (startIndex != -1 && endIndex != -1) {
    final newButton = '''                // Start Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: (players.length >= 4 && _totalRoles == players.length)
                            ? (widget.isInteractive ? [const Color(0xFFFF512F), const Color(0xFFF09819)] : [const Color(0xFFDD2476), const Color(0xFF900C3F)])
                            : [Colors.grey.shade800, Colors.grey.shade900],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (players.length >= 4 && _totalRoles == players.length)
                          ? [BoxShadow(color: widget.isInteractive ? const Color(0xFFFF512F) : const Color(0xFFDD2476), blurRadius: 10, spreadRadius: 1)]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: (players.length >= 4 && _totalRoles == players.length) 
                            ? () => _startGame(widget.isInteractive) 
                            : () {
                               if (players.length < 4) _showError('يجب إضافة 4 لاعبين على الأقل');
                               else _showError('عدد الأدوار لا يطابق عدد اللاعبين');
                            },
                        child: Center(
                          child: Text(widget.isInteractive ? 'بدء اللعب التفاعلي (QR)' : 'بدء اللعب',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
''';
    content = content.replaceRange(startIndex, endIndex + endStr.length, newButton);
  }

  file.writeAsStringSync(content);
}
