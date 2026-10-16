import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';
import 'package:mafia_nightfall/presentation/premium/theme_experience_preview.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ThemeGalleryContent(
    selectedThemeId: ref.watch(selectedThemeProvider),
    isPremium: ref.watch(premiumProvider),
    onApply: (id) => ref.read(selectedThemeProvider.notifier).selectTheme(id),
  );
}

class ThemeGalleryContent extends StatelessWidget {
  const ThemeGalleryContent({
    super.key,
    required this.selectedThemeId,
    required this.isPremium,
    required this.onApply,
  });
  final String selectedThemeId;
  final bool isPremium;
  final Future<void> Function(String id) onApply;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الثيمات')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'اختر ثيم التطبيق. يمكنك معاينة الألوان قبل تطبيقه.',
              style: TextStyle(color: context.visual.textSecondary),
            ),
            const SizedBox(height: 12),
            for (final palette in ThemeCatalog.themes)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: palette.actionGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(palette.icon, color: palette.textPrimary),
                  ),
                  title: Text(palette.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      ThemeSwatches(palette: palette, size: 16),
                      const SizedBox(height: 8),
                      Text(
                        palette.isPremium ? 'Premium' : 'الثيم الأصلي · مجاني',
                        style: TextStyle(
                          color: palette.isPremium
                              ? premiumGold
                              : context.visual.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    selectedThemeId == palette.id
                        ? Icons.check_circle_rounded
                        : palette.isPremium && !isPremium
                        ? Icons.lock_outline
                        : Icons.chevron_left_rounded,
                    color: selectedThemeId == palette.id
                        ? AppTheme.success
                        : context.visual.textSecondary,
                  ),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _ThemePreviewSheet(
                      palette: palette,
                      canApply: !palette.isPremium || isPremium,
                      onApply: onApply,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ThemePreviewSheet extends StatefulWidget {
  const _ThemePreviewSheet({
    required this.palette,
    required this.canApply,
    required this.onApply,
  });
  final ThemePalette palette;
  final bool canApply;
  final Future<void> Function(String id) onApply;
  @override
  State<_ThemePreviewSheet> createState() => _ThemePreviewSheetState();
}

class _ThemePreviewSheetState extends State<_ThemePreviewSheet> {
  bool _saving = false;
  String? _error;
  Future<void> _apply() async {
    if (_saving || !widget.canApply) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onApply(widget.palette.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر حفظ الثيم. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.previewTheme(widget.palette),
    child: Builder(
      builder: (context) => Container(
        color: widget.palette.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'معاينة الثيم',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.palette.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.palette.description,
                style: TextStyle(color: context.visual.textSecondary),
              ),
              const SizedBox(height: 16),
              const ThemeExperiencePreview(),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
              if (widget.canApply)
                FilledButton(
                  onPressed: _saving ? null : _apply,
                  child: Text(_saving ? 'جارٍ الحفظ…' : 'تطبيق هذا الثيم'),
                )
              else ...[
                const Text(
                  'Premium · يلزم اشتراك لتطبيق هذا الثيم',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: premiumGold),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PricingScreen(),
                      ),
                    );
                  },
                  child: const Text('Upgrade to Premium'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
