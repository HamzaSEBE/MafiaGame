import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/application/premium_service.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedThemeProvider);
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('النسخة الاحترافية 👑', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.workspace_premium, size: 80, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'افتح جميع الميزات!',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            Text(
              'احصل على وصول كامل لتغيير الثيمات، الخلفيات، وميزات قادمة رهيبة جداً!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 40),

            _buildPricingCard(
              context: context,
              ref: ref,
              title: 'اشتراك شهري',
              price: r'$1.99',
              period: '/ شهر',
              description: 'إلغاء في أي وقت. مثالي للتجربة.',
              color: AppTheme.iconColor3,
            ),
            
            const SizedBox(height: 24),
            
            _buildPricingCard(
              context: context,
              ref: ref,
              title: 'مدى الحياة',
              price: r'$20.00',
              period: ' تدفع مرة واحدة',
              description: 'أفضل قيمة! افتح كل شيء للأبد ولن تدفع مجدداً.',
              color: AppTheme.accent,
              isPopular: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String price,
    required String period,
    required String description,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: isPopular ? 2 : 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                    Text(period, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontFamily: 'Cairo')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontFamily: 'Cairo')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: color.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      _simulatePurchase(context, ref);
                    },
                    child: const Text('اشترك الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -12,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Text('الأكثر مبيعاً 🔥', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ),
        ],
      ),
    );
  }

  void _simulatePurchase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('محاكاة الشراء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: const Text('هذه الواجهة لغرض التجربة حالياً. اضغط "موافق" لتفعيل النسخة الاحترافية مجاناً للاختبار.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            onPressed: () {
              ref.read(premiumProvider.notifier).unlockPremium();
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close pricing screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تفعيل النسخة الاحترافية بنجاح! 👑', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
              );
            },
            child: const Text('موافق', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
