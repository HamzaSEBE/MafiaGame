import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// In the future, this provider will control the actual app theme.
final selectedThemeProvider = StateProvider<String>((ref) => 'dark_blood');

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(selectedThemeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الثيمات 👑', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'اختر الستايل المفضل لك:',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 24),
          
          _buildThemeCard(
            context: context,
            ref: ref,
            id: 'dark_blood',
            title: 'Dark Blood (الأساسي)',
            description: 'الثيم الأحمر الدموي الفخم للمافيا.',
            color1: const Color(0xFF8B0000),
            color2: const Color(0xFF4A0000),
            isSelected: currentTheme == 'dark_blood',
          ),
          
          _buildThemeCard(
            context: context,
            ref: ref,
            id: 'midnight_blue',
            title: 'Midnight Blue',
            description: 'ثيم أزرق ليلي هادئ وبارد.',
            color1: const Color(0xFF0F2027),
            color2: const Color(0xFF203A43),
            isSelected: currentTheme == 'midnight_blue',
          ),
          
          _buildThemeCard(
            context: context,
            ref: ref,
            id: 'emerald_shadow',
            title: 'Emerald Shadow',
            description: 'أخضر زمردي فاخر يشبه غرف البوكر السرية.',
            color1: const Color(0xFF004D40),
            color2: const Color(0xFF00251A),
            isSelected: currentTheme == 'emerald_shadow',
          ),

          _buildThemeCard(
            context: context,
            ref: ref,
            id: 'royal_gold',
            title: 'Royal Gold',
            description: 'ثيم ذهبي فاخر لكبار الشخصيات.',
            color1: const Color(0xFFFFD700),
            color2: const Color(0xFFB8860B),
            isSelected: currentTheme == 'royal_gold',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required String title,
    required String description,
    required Color color1,
    required Color color2,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedThemeProvider.notifier).state = id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تفعيل ثيم: $title بنجاح!', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontFamily: 'Cairo')),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.amber, size: 32)
              else
                Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.5), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
