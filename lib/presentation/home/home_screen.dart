import 'dart:convert';
import 'package:mafia_nightfall/presentation/widgets/game_mode_card.dart';
import 'package:mafia_nightfall/data/repositories/profile_repository.dart';
import 'package:mafia_nightfall/presentation/home/game_recovery_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/instructions/instructions_screen.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/presentation/profile/profile_screen.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/stats/stats_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, Widget destination) {
    ref.read(audioManagerProvider).playClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedThemeProvider);
    final isPremium = ref.watch(premiumProvider);
    final user = ref.watch(authUserProvider).asData?.value;
    final profile = ref.watch(accountProfileProvider).asData?.value;
    final displayName =
        profile?['displayName'] as String? ??
        user?.displayName ??
        'أهلاً باللاعب';
    final base64Photo =
        (profile?['photoBase64'] ?? profile?['avatarBase64']) as String?;
    final storedAvatar = ref.watch(profileAvatarProvider).asData?.value;
    ImageProvider? avatar = storedAvatar == null
        ? null
        : MemoryImage(storedAvatar);
    if (avatar == null && base64Photo != null && base64Photo.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(base64Photo));
      } catch (_) {
        /* Keep the default avatar. */
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.visual.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    sliver: SliverList.list(
                      children: [
                        _buildHeader(context, ref, displayName, avatar),
                        const SizedBox(height: 30),
                        _buildBrand(context),
                        const SizedBox(height: 32),
                        const GameRecoveryCard(),
                        GameModeCard(
                          title: 'لعب تفاعلي',
                          subtitle: 'كل لاعب ينضم من هاتفه عبر رمز QR',
                          icon: Icons.qr_code_scanner_rounded,
                          isPrimary: true,
                          onTap: () => _open(
                            context,
                            ref,
                            const SetupScreen(isInteractive: true),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GameModeCard(
                          title: 'لعب محلي',
                          subtitle: 'جهاز واحد، وكل الأصدقاء حولك',
                          icon: Icons.phone_android_rounded,
                          isPrimary: false,
                          onTap: () => _open(
                            context,
                            ref,
                            const SetupScreen(isInteractive: false),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.leaderboard_outlined,
                                label: 'الإحصائيات',
                                onTap: () =>
                                    _open(context, ref, const StatsScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.history_edu_outlined,
                                label: 'السجل',
                                onTap: () => _open(
                                  context,
                                  ref,
                                  const GameHistoryScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.menu_book_outlined,
                                label: 'التعليمات',
                                onTap: () => _open(
                                  context,
                                  ref,
                                  const InstructionsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PremiumUpgradeButton(
                          isPremium: isPremium,
                          onTap: () =>
                              _open(context, ref, const PricingScreen()),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: context.visual.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'اللعب عن بُعد · قيد التطوير',
                                style: TextStyle(
                                  color: context.visual.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String displayName,
    ImageProvider? avatar,
  ) => Row(
    children: [
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context, ref, const ProfileScreen()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: context.visual.surfaceHigh,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Icon(
                          Icons.person_outline_rounded,
                          color: context.visual.accent,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جاهز لليلة جديدة؟',
                        style: TextStyle(
                          color: context.visual.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.visual.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      IconButton.filledTonal(
        onPressed: () => _open(context, ref, const SettingsScreen()),
        tooltip: 'الإعدادات',
        icon: const Icon(Icons.tune_rounded, size: 23),
      ),
    ],
  );

  Widget _buildBrand(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.visual.surface.withValues(alpha: 0.7),
          border: Border.all(
            color: context.visual.accent.withValues(alpha: 0.23),
          ),
          boxShadow: [
            BoxShadow(
              color: context.visual.glowColor.withValues(alpha: 0.1),
              blurRadius: 46,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.theater_comedy_outlined,
          color: context.visual.accent,
          size: 52,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'مافيا عالشوارب',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        'البقاء للأذكى',
        style: TextStyle(color: context.visual.textSecondary, fontSize: 14),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.visual.surface.withValues(alpha: 0.45),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: context.visual.textSecondary, size: 23),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.visual.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
