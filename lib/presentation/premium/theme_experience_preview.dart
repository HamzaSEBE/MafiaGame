import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/widgets/game_mode_card.dart';
import 'package:mafia_nightfall/presentation/widgets/game_round_header.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

/// Uses real presentation components with static sample data and no listeners.
class ThemeExperiencePreview extends StatefulWidget {
  const ThemeExperiencePreview({super.key});
  @override
  State<ThemeExperiencePreview> createState() => _ThemeExperiencePreviewState();
}

class _ThemeExperiencePreviewState extends State<ThemeExperiencePreview> {
  bool _night = false;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.visual.background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.visual.surfaceHigh),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('من داخل اللعبة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GameModeCard(
          title: 'لعب تفاعلي',
          subtitle: 'طاولة واحدة، وكل الأصدقاء حولك',
          icon: Icons.qr_code_scanner_rounded,
          isPrimary: true,
          onTap: () => setState(() => _night = !_night),
        ),
        const SizedBox(height: 16),
        GameRoundHeader(round: 3, isNight: _night),
        const SizedBox(height: 12),
        Text(
          'جرّب الأجواء النهارية والليلية',
          style: TextStyle(color: context.visual.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _night = false),
              child: const Text('النهار'),
            ),
            OutlinedButton(
              onPressed: () => setState(() => _night = true),
              child: const Text('الليل'),
            ),
          ],
        ),
      ],
    ),
  );
}
