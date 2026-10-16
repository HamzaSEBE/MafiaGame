import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/presentation/premium/premium_catalog.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PremiumHubContent(
    isPremium: ref.watch(premiumProvider),
    accessLoading: ref.watch(premiumAccessProvider).isLoading,
    accessError: ref.watch(premiumAccessProvider).hasError,
    onExploreThemes: () => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ThemesScreen()),
    ),
  );
}

/// Pricing presentation has no purchase side effects until billing is shipped.
class PremiumHubContent extends StatelessWidget {
  const PremiumHubContent({
    super.key,
    required this.isPremium,
    required this.onExploreThemes,
    this.features = premiumFeatures,
    this.featureActions = const {},
    this.featurePreviews = const {},
    this.accessLoading = false,
    this.accessError = false,
  });
  final bool isPremium;
  final bool accessLoading;
  final bool accessError;
  final List<PremiumFeature> features;
  final Map<String, VoidCallback> featureActions;
  final Map<String, WidgetBuilder> featurePreviews;
  final VoidCallback onExploreThemes;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pricing · Premium')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: premiumGold,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Premium',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'خصّص تجربتك مع مزايا إضافية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.visual.textSecondary),
            ),
            const SizedBox(height: 24),
            Text('الباقات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final plan in premiumPlans)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.price,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: premiumGold,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.period,
                            style: TextStyle(
                              color: context.visual.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              'أسعار العرض الحالية؛ الشراء داخل التطبيق لم يُفعّل بعد.',
              style: TextStyle(
                color: context.visual.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'المزايا المتاحة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final feature in features.where(
              (f) => f.releaseStatus == PremiumReleaseStatus.available,
            ))
              _feature(context, feature, enabled: true),
            if (features.any(
              (f) => f.releaseStatus == PremiumReleaseStatus.announced,
            )) ...[
              const SizedBox(height: 20),
              Text('قريباً', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final feature in features.where(
                (f) => f.releaseStatus == PremiumReleaseStatus.announced,
              ))
                _feature(context, feature, enabled: false),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'المزايا القادمة غير متاحة للاستخدام أو ضمن مزايا الاشتراك الحالية.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.visual.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: premiumGold.withValues(alpha: .3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    accessLoading
                        ? 'جارٍ التحقق من الاشتراك…'
                        : accessError
                        ? 'تعذر التحقق من الاشتراك. حاول لاحقاً.'
                        : isPremium
                        ? 'اشتراك Premium مفعّل'
                        : 'الاشتراك في Premium',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPremium
                        ? 'الثيمات الحصرية متاحة لك من الإعدادات.'
                        : 'تفعيل الاشتراك سيُتاح عند ربط الدفع داخل التطبيق.',
                    style: TextStyle(color: context.visual.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (!isPremium)
                    const FilledButton(
                      onPressed: null,
                      child: Text('الاشتراك غير متاح حالياً'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _feature(
    BuildContext context,
    PremiumFeature feature, {
    required bool enabled,
  }) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(feature.icon, color: premiumGold),
      title: Text(feature.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(feature.description),
          const SizedBox(height: 6),
          Text(
            enabled ? 'Premium' : 'Premium · قريباً',
            style: const TextStyle(color: premiumGold, fontSize: 12),
          ),
          if (featurePreviews[feature.id] != null)
            featurePreviews[feature.id]!(context),
        ],
      ),
      trailing: enabled
          ? const Icon(Icons.chevron_left_rounded)
          : const Icon(Icons.schedule_rounded),
      onTap: enabled
          ? featureActions[feature.id] ??
                (feature.id == PremiumFeatureId.themes ? onExploreThemes : null)
          : null,
    ),
  );
}
