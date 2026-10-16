import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:mafia_nightfall/presentation/settings/role_names_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ThemeCatalog.byId(ref.watch(selectedThemeProvider));
    final isPremium = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'تخصيص التجربة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _settingsTile(
                context,
                title: 'الثيمات',
                subtitle: '${palette.name}\nPremium · ثيمات حصرية باشتراك',
                icon: Icons.palette_outlined,
                color: palette.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ThemesScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _settingsTile(
                context,
                title: 'أسماء الأدوار',
                subtitle: 'خصّص أسماء الأدوار لتناسب مجموعتك',
                icon: Icons.edit_note_rounded,
                color: context.visual.iconColor2,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RoleNamesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PremiumUpgradeButton(
                isPremium: isPremium,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PricingScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Material(
    color: context.visual.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: context.visual.surfaceHigh),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.visual.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.visual.textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_left_rounded,
              color: context.visual.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    ),
  );
}
