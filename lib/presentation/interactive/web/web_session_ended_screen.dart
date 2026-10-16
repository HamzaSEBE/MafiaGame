import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/interactive/web/player_components.dart';

class WebSessionEndedScreen extends StatelessWidget {
  const WebSessionEndedScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlayerPage(
    title: 'أُسدل الستار',
    subtitle: 'لكل مدينة حكاية… ولكل ليلة أسرارها.',
    status: 'انتهت الجلسة',
    child: PlayerNotice(
      title: 'انتهت اللعبة',
      message:
          'أنهى الحكم هذه الجلسة. يمكنك إغلاق الصفحة، أو مسح رمز QR جديد للانضمام إلى ليلة أخرى.',
      icon: Icons.flag_outlined,
    ),
  );
}
