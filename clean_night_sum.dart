import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_summary_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r"title: const Text\('.*'\),"), "title: const Text('ملخص الليل (للحكم فقط)', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),");
  content = content.replaceAll(RegExp(r"Text\('.*!', style: TextStyle\(color: AppTheme.specialAction"), "Text('رد فعل المواطن الشجاع!', style: TextStyle(color: AppTheme.specialAction");
  content = content.replaceAll(RegExp(r"const Text\('.*:', style: TextStyle\(fontFamily: 'Cairo'\)\),"), "const Text('بما أنك قُتلت، يمكنك أخذ لاعب معك:', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),");
  content = content.replaceAll(RegExp(r"child: const Text\('U.O.O.O ', style:"), "child: const Text('تخطي', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.O.O.O.O. O.O.O.O.O.O.', style:"), "child: const Text('تأكيد واغتيال', style:");
  
  content = content.replaceAll(RegExp(r"title: const Text\('.*!', style: TextStyle\(color: AppTheme.death"), "title: const Text('ضحية المواطن الشجاع!', style: TextStyle(color: AppTheme.death");
  content = content.replaceAll(RegExp(r"Text\('U.O.U+: \$\{AppTheme.roleArabicName\(target.role\)\}',"), "Text('كان: \${AppTheme.roleArabicName(target.role)}',");
  
  content = content.replaceAll(RegExp(r"child: const Text\('.*',\s*style: TextStyle\(fontSize: 16,\s*fontWeight: FontWeight.bold,\s*color: Colors.white\)\),"), "child: const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),");
  
  content = content.replaceAll(RegExp(r"const Text\(\s*'.*:',\s*style: TextStyle\(fontSize: 22"), "const Text('انتهت الليلة، وإليك ما حدث:', style: TextStyle(fontSize: 22");
  
  content = content.replaceAll(RegExp(r"Text\('.*!', style: TextStyle\(color: AppTheme.success"), "Text('نجحت الحماية! لم يُقتل أحد.', style: TextStyle(color: AppTheme.success");
  
  content = content.replaceAll(RegExp(r"const Text\('.*:\',\s*style: TextStyle\(color: AppTheme.error"), "const Text('ضحية الليل (تم اغتياله):', style: TextStyle(color: AppTheme.error");
  
  content = content.replaceAll(RegExp(r"title: '.*:',\s*names: getNames\(silencedIds\),\s*icon: Icons.volume_off,"), "title: 'تم إسكاتهم (لا يحق لهم الكلام):', names: getNames(silencedIds), icon: Icons.volume_off,");
  
  content = content.replaceAll(RegExp(r"child: Text\(\s*state.phase == Phase.triggeredAbility \? '.*!' : '.*',\s*style: const TextStyle\(fontSize: 18"), "child: Text(state.phase == Phase.triggeredAbility ? 'رد فعل المواطن الشجاع!' : 'بدء النهار', style: const TextStyle(fontSize: 18");

  file.writeAsStringSync(content);
}