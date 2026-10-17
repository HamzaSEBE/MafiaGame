import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/interactive/web/player_components.dart';

class WebSessionEndedScreen extends StatelessWidget {
  const WebSessionEndedScreen({super.key, this.waitingForRematch = false});
  final bool waitingForRematch;
  @override
  Widget build(BuildContext context) => PlayerPage(
    title: 'أُسدل الستار',
    subtitle: 'لكل مدينة حكاية… ولكل ليلة أسرارها.',
    status: waitingForRematch ? 'بانتظار الحكم' : 'انتهت الجلسة',
    child: PlayerNotice(
      title: 'انتهت اللعبة',
      message: waitingForRematch
          ? 'أبقِ الصفحة مفتوحة. إذا أعاد الحكم المباراة ستبدأ هنا تلقائياً بنفس اسمك ودورك الجديد، دون مسح QR.'
          : 'أنهى الحكم هذه الجلسة. يمكنك إغلاق الصفحة.',
      icon: Icons.flag_outlined,
    ),
  );
}
