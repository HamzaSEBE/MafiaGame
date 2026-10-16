import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

/// Shared, static layout for every guest state. No animation loop or blur layer.
class PlayerPage extends StatelessWidget {
  const PlayerPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.status = 'جلسة خاصة',
    this.bottom,
  });
  final String title, subtitle, status;
  final Widget child;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: context.visual.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.visual.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient:
                                      context.visual.palette.actionGradient,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: context.visual.iconColor2.withValues(
                                      alpha: .45,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.theater_comedy_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مافيا عالشوارب',
                                      style: TextStyle(
                                        color: context.visual.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'THE CITY KEEPS SECRETS',
                                      style: TextStyle(
                                        color: context.visual.textSecondary,
                                        fontSize: 9,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          PlayerTag(label: status),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.4,
                              fontWeight: FontWeight.w900,
                              color: context.visual.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.8,
                              color: context.visual.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverToBoxAdapter(child: child),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: context.visual.background,
                border: Border(
                  top: BorderSide(color: context.visual.surfaceHigh),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                      child: bottom,
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}

class PlayerTag extends StatelessWidget {
  const PlayerTag({
    super.key,
    required this.label,
    this.color,
    this.icon = Icons.circle,
  });
  final String label;
  final Color? color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.visual.iconColor2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ink.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: ink),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key, required this.child, this.highlight = false});
  final Widget child;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [context.visual.surface, context.visual.background],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: highlight
            ? context.visual.iconColor2.withValues(alpha: .5)
            : context.visual.surfaceHigh,
      ),
    ),
    child: child,
  );
}

class PlayerNotice extends StatelessWidget {
  const PlayerNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.hourglass_empty_rounded,
    this.error = false,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final bool error;
  final Widget? action;
  @override
  Widget build(BuildContext context) => PlayerPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 32,
          color: error ? AppTheme.error : context.visual.iconColor2,
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: context.visual.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(color: context.visual.textSecondary, height: 1.8),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

class PlayerChoice extends StatelessWidget {
  const PlayerChoice({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });
  final String name;
  final bool selected;
  final VoidCallback? onTap;
  final String? subtitle, badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.visual.palette.cardEnd
            : context.visual.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? context.visual.iconColor2
                : context.visual.surfaceHigh,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.visual.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    name.isEmpty ? '؟' : name.characters.first,
                    style: TextStyle(
                      color: context.visual.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: context.visual.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: context.visual.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  PlayerTag(label: badge!),
                ],
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? context.visual.iconColor2
                      : context.visual.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
