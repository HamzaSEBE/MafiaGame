import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';

const premiumGold = Color(0xFFE3C78D);

class ThemeSwatches extends StatelessWidget {
  const ThemeSwatches({super.key, required this.palette, this.size = 20});
  final ThemePalette palette;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: palette.swatches
          .map(
            (color) => Container(
              width: size,
              height: size,
              margin: const EdgeInsetsDirectional.only(end: 5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
            ),
          )
          .toList(),
    ),
  );
}

/// An illustration made from the same tokens used by the real application.
/// It is intentionally static and cheap to draw, even in long theme galleries.
class PremiumUpgradeButton extends StatelessWidget {
  const PremiumUpgradeButton({
    super.key,
    required this.isPremium,
    required this.onTap,
  });
  final bool isPremium;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(
      Icons.workspace_premium_outlined,
      color: premiumGold,
      size: 20,
    ),
    label: Text(isPremium ? 'اشتراك Premium' : 'Upgrade to Premium'),
    style: OutlinedButton.styleFrom(
      foregroundColor: context.visual.textPrimary,
      side: BorderSide(color: premiumGold.withValues(alpha: .4)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
  );
}

/// Announced only: no voice activation or entitlement grant before release.
class AiVoiceAssistantSetting extends StatelessWidget {
  const AiVoiceAssistantSetting({super.key});
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_none_rounded, color: premiumGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Voice Assistant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Switch(value: false, onChanged: null),
            ],
          ),
          const Text(
            'Premium · قريباً',
            style: TextStyle(color: premiumGold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'مساعد صوتي لإدارة الجولة. سيُتاح في تحديث لاحق.',
            style: TextStyle(color: context.visual.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
