import 'package:flutter/material.dart';


class NewspaperWidget extends StatelessWidget {
  final String narrative;

  const NewspaperWidget({super.key, required this.narrative});

  @override
  Widget build(BuildContext context) {
    // A brilliant, realistic vintage newspaper design
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECD8), // Vintage paper color
        borderRadius: BorderRadius.circular(4), // Sharp edges like paper
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          )
        ],
        // Subtle paper texture overlay using gradient noise (simulated)
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [Color(0xFFF4ECD8), Color(0xFFE8DDBF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top small header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العدد: ${now.millisecondsSinceEpoch.toString().substring(5, 10)}',
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 2, color: Colors.black87),
            Container(height: 5, margin: const EdgeInsets.only(top: 2), color: Colors.black87),
            const SizedBox(height: 16),
            
            // Huge Title
            const Text(
              'جريدة المدينة',
              style: TextStyle(
                fontFamily: 'Cairo', // Or a serif font if available
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Text(
              'أخبار المافيا العاجلة - النسخة الحصرية',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(height: 2, color: Colors.black87),
            const SizedBox(height: 24),
            
            // The article body
            _buildArticleBody(),
            
            const SizedBox(height: 32),
            Container(height: 1, color: Colors.black38),
            const SizedBox(height: 12),
            const Text(
              'طُبعت في مطابع المدينة السرية - جميع الحقوق محفوظة ©',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleBody() {
    List<Widget> paragraphs = [];
    final lines = narrative.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('[ أحداث الليلة') || line.startsWith('[ نهار اليوم')) {
        // Section Header (Sub-headline)
        paragraphs.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.replaceAll('[', '').replaceAll(']', '').trim(),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      } else if (line.startsWith('النتيجة النهائية:')) {
        // Conclusion / Final verdict
        paragraphs.add(
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Text(
              line,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      } else {
        // Normal paragraph, but with rich text for names in parentheses ($name)
        paragraphs.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _parseParagraph(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs,
    );
  }

  Widget _parseParagraph(String line) {
    List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\(\$(.*?)\)');
    int start = 0;
    final matches = exp.allMatches(line);
    
    // First letter drop cap simulation for the very first normal paragraph (optional)
    // but Arabic typography works better with just bold highlighting.
    
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: line.substring(start, match.start)));
      }
      // Name highlighting (like bold news ink)
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.w900, 
          color: Color(0xFF8B0000), // Dark blood red ink for names
          fontSize: 17,
        ),
      ));
      start = match.end;
    }
    
    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start)));
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF2C2C2C), // Dark charcoal ink
          fontSize: 16,
          fontFamily: 'Cairo',
          height: 1.8,
          fontWeight: FontWeight.w600,
        ),
        children: spans,
      ),
    );
  }
}
