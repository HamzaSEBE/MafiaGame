import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_summary_screen.dart');
  var content = file.readAsStringSync();
  
  // Clean garbled Arabic strings
  content = content.replaceAll("U,O  OO-O_", "لا أحد");
  content = content.replaceAll("U.OUU^U,", "مجهول");
  content = content.replaceAll("U.U,OrO O U,U,USU, (U,U,O-UU. U?U,O)", "ملخص الليلة (للحكم فقط)");
  content = content.replaceAll("O U+OUU% O U,U,USU,OO U^OU,USU U.O  O-O_O U?US O U,O1OU.Oc:", "انتهت الليلة، وإليك ما حدث في الظلام:");
  content = content.replaceAll("O\"U+O O U,U.U^O OU+USU+ O-U.O O U,UO_U? O\"U+OO O-! U,U. USU?U,OU, OO-O_.", "نجحت الحماية! لم يمت أحد.");
  content = content.replaceAll("O O-USOc O U,U,USU, (OU. O OOUSO U,U):", "ضحية الليلة (تم اغتياله):");
  content = content.replaceAll("OU. OO3UO OUU. (U,O  USO-U, U,UU. O U,UU,O U.):", "تم إسكاتهم (لا يحق لهم التحدث):");
  content = content.replaceAll("OO_ U?O1U, O U,U.U^O OU+ O U,O'OO O1!", "تفعيل قدرة المواطن الثائر!");
  content = content.replaceAll("O\"O_O O U,U+UO O", "ابدأ النهار");
  
  // Scaffold styles
  content = content.replaceAll("Scaffold(\n      appBar:", "Scaffold(\n      backgroundColor: const Color(0xFF07070B),\n      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,");
  content = content.replaceAll("body: Padding(", "body: Stack(children: [ Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [Color(0xFF130E0A), Color(0xFF07070B)])))), Padding(");
  
  final lastIndex = content.lastIndexOf("));\n  }");
  if (lastIndex != -1) {
    content = content.replaceRange(lastIndex, lastIndex + 7, "],)));\n  }");
  }

  // Summary Card styling
  content = content.replaceAll("color: AppTheme.surfaceHigh", "color: Colors.white.withValues(alpha: 0.05)");

  file.writeAsStringSync(content);
}