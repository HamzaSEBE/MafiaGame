import 'package:flutter/material.dart';

/// Shipped benefits and explicitly announced placeholders for the pricing page.
abstract final class PremiumFeatureId {
  static const themes = 'themes';
  static const aiVoiceAssistant = 'ai_voice_assistant';
}

enum PremiumReleaseStatus { available, announced, hidden }

@immutable
class PremiumFeature {
  const PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    this.releaseStatus = PremiumReleaseStatus.available,
  });
  final String id;
  final PremiumReleaseStatus releaseStatus;
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
}

const premiumFeatures = <PremiumFeature>[
  PremiumFeature(
    id: PremiumFeatureId.themes,
    title: 'ثيمات التطبيق',
    description:
        'ثلاث مجموعات حصرية، لكل منها ألوانها وخلفياتها وتفاصيلها المتناسقة. اختر الأجواء التي تشبهك.',
    icon: Icons.palette_outlined,
    actionLabel: 'الثيمات في الإعدادات',
  ),
  PremiumFeature(
    id: PremiumFeatureId.aiVoiceAssistant,
    title: 'AI Voice Assistant',
    description:
        'مساعد صوتي للجولات. يظهر في إعدادات وقوانين اللعبة؛ لم يتوفر بعد.',
    icon: Icons.mic_none_rounded,
    actionLabel: 'قريباً',
    releaseStatus: PremiumReleaseStatus.announced,
  ),
];

/// Existing display prices. Store products must supply verified prices before
/// purchases are enabled; these entries never grant membership.
@immutable
class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
  });
  final String id;
  final String title;
  final String price;
  final String period;
}

const premiumPlans = <PremiumPlan>[
  PremiumPlan(
    id: 'monthly',
    title: 'اشتراك شهري',
    price: r'$1.99',
    period: '/ شهر',
  ),
  PremiumPlan(
    id: 'lifetime',
    title: 'مدى الحياة',
    price: r'$20.00',
    period: 'مرة واحدة',
  ),
];
