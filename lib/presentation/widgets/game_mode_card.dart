import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class GameModeCard extends StatelessWidget {
  const GameModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Ink(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  context.visual.primaryCardStart,
                  context.visual.primaryCardEnd,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        color: isPrimary ? null : context.visual.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPrimary
              ? context.visual.accent.withValues(alpha: 0.4)
              : context.visual.surfaceHigh,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? context.visual.textPrimary
                      : context.visual.accent,
                  size: 27,
                ),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.8)
                            : context.visual.textSecondary,
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_left_rounded,
                color: context.visual.textPrimary.withValues(alpha: 0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
