import re

with open('lib/presentation/night/night_summary_screen.dart', 'r') as f:
    content = f.read()

old_layout = """                    const Text(
                      'انتهى الليل، وإليك ما حدث في العتمة:',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (successfulProtections.isNotEmpty)
                      Container("""

new_layout = """                    const Text(
                      'انتهى الليل، وإليك ما حدث في العتمة:',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            if (successfulProtections.isNotEmpty)
                              Container("""

content = content.replace(old_layout, new_layout)

old_layout_end = """                      _SummaryCard(
                        title: 'تم إسكاتهم (لا يحق لهم الكلام):',
                        names: getNames(silencedIds),
                        icon: Icons.volume_off,
                        color: Colors.blueAccent,
                      ),
                    const Spacer(),
                    SizedBox(
                      height: 55,"""

new_layout_end = """                      _SummaryCard(
                        title: 'تم إسكاتهم (لا يحق لهم الكلام):',
                        names: getNames(silencedIds),
                        icon: Icons.volume_off,
                        color: Colors.blueAccent,
                      ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 55,"""

content = content.replace(old_layout_end, new_layout_end)

with open('lib/presentation/night/night_summary_screen.dart', 'w') as f:
    f.write(content)
