import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/presentation/settings/role_names_screen.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!isPremium) ...[
            _buildPremiumBanner(context),
            const SizedBox(height: 24),
          ],
          
          _buildSettingsTile(
            context: context,
            title: 'تغيير أسماء الأدوار',
            subtitle: 'تخصيص أسماء الأدوار كما تحب',
            icon: Icons.edit_note,
            iconColor: Colors.blueAccent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleNamesScreen()));
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            context: context,
            title: 'تغيير ثيم التطبيق',
            subtitle: 'تغيير الألوان والخلفيات (Premium)',
            icon: Icons.palette,
            iconColor: isPremium ? Colors.purpleAccent : Colors.grey,
            isPremiumFeature: true,
            isLocked: !isPremium,
            onTap: () {
              if (!isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
              } else {
Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemesScreen()));
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            context: context,
            title: 'تغيير خلفية اللعب',
            subtitle: 'تخصيص الصور الخلفية (Premium)',
            icon: Icons.wallpaper,
            iconColor: isPremium ? Colors.greenAccent : Colors.grey,
            isPremiumFeature: true,
            isLocked: !isPremium,
            onTap: () {
              if (!isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('شاشة الخلفيات قيد التطوير!', style: TextStyle(fontFamily: 'Cairo'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النسخة الاحترافية 👑', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                  Text('افتح جميع الميزات والثيمات', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontFamily: 'Cairo')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isPremiumFeature = false,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPremiumFeature && isLocked ? Colors.white.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(color: isLocked ? Colors.grey : Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      if (isPremiumFeature) ...[
                        const SizedBox(width: 8),
                        Icon(isLocked ? Icons.lock : Icons.workspace_premium, color: const Color(0xFFFFD700), size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontFamily: 'Cairo')),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}
