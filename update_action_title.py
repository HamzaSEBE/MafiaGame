import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

old_action = """  String _actionTitle(String type) => switch (type) {
        'vote' => 'صوّت ضد لاعب للإقصاء',
        'assassination' => 'اختر هدف الاغتيال',
        'protection' => 'اختر من تريد حمايته',
        'investigation' => 'اختر لاعبًا للتحقيق معه',
        'silence' => 'اختر من تريد إسكات صوته',
        'retaliation' => 'اختر هدف الانتقام',
        _ => 'اختر هدف الحركة',
      };"""

new_action = """  String _actionTitle(String type) => switch (type) {
        'vote' => 'صوّت ضد لاعب للإقصاء',
        'assassination' => 'اختر هدف الاغتيال',
        'protection' => 'اختر من تريد حمايته',
        'investigation' => 'اختر لاعبًا للتحقيق معه',
        'silence' => 'اختر من تريد إسكات صوته',
        'retaliation' => 'اختر هدف الانتقام',
        'sniperKill' => 'اختر هدف القنص (أو اختر نفسك للتخطي)',
        'sleep' => 'لا يوجد لديك قدرة (اختر اسمك للتأكيد)',
        _ => 'اختر هدف الحركة',
      };"""

content = content.replace(old_action, new_action)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
