import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class GameRoundHeader extends StatelessWidget {
  const GameRoundHeader({super.key, required this.round, this.isNight = false});
  final int round;
  final bool isNight;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        isNight ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
        color: context.visual.accent,
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          '${isNight ? 'الليل' : 'النهار'} $round',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  );
}
