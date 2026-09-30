import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('تعليمات اللعبة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('الهدف من اللعبة'),
            _buildParagraph(
              'مافيا عالشوارب هي لعبة استنتاج اجتماعي وخداع. ينقسم اللاعبون إلى طرفين رئيسيين: المافيا (الأقلية الشريرة) والمواطنون (الأغلبية الجاهلة)، بالإضافة إلى الجوكر (الطرف المستقل). هدف المافيا تصفية المواطنين، وهدف المواطنين اكتشاف المافيا وإعدامهم.'
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('مراحل اللعبة'),
            _buildPhaseCard(
              title: 'مرحلة الليل 🌙',
              description: 'يغمض جميع اللاعبين أعينهم. يقوم الحكم بإيقاظ كل دور خاص على حدة (المافيا للاغتيال، شيخ المواطنين للتحقيق، إلخ). لا يُسمح بالكلام في هذه المرحلة أبداً.',
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 12),
            _buildPhaseCard(
              title: 'مرحلة النهار ☀️',
              description: 'يفتح الجميع أعينهم. يُعلن الحكم عن الضحية. تبدأ مرحلة النقاش، الاتهامات والدفاع. ينتهي النهار بتصويت ديمقراطي لإعدام المشتبه به الأكثر تصويتاً.',
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('شرح الأدوار'),
            _buildRoleCard('شيخ المافيا', 'زعيم المافيا القوي. يشارك في القتل ليلاً ويقود العصابة.', Icons.account_circle, Colors.red),
            _buildRoleCard('بنت المافيا', 'المتسللة. تختار لاعباً كل ليلة لإسكاته، وفي نهار اليوم التالي يُمنع هذا اللاعب من الكلام أو الدفاع عن نفسه تماماً.', Icons.favorite, Colors.redAccent),
            _buildRoleCard('مافيا عادي', 'أحد أفراد العصابة. يستيقظ مع باقي المافيا للتصويت على ضحية الليل.', Icons.local_fire_department, Colors.redAccent),
            _buildRoleCard('شيخ المواطنين', 'المحقق السري. يستيقظ ليلاً ليختار لاعباً واحداً ويسأل الحكم عن هويته (هل هو مافيا أم لا).', Icons.search, Colors.blue),
            _buildRoleCard('بنت المواطنين', 'الملاك الحارس. تختار لاعباً كل ليلة لتحميه. إذا حاولت المافيا قتله في تلك الليلة، ينجو ولا يموت.', Icons.health_and_safety, Colors.lightBlue),
            _buildRoleCard('المواطن الشجاع', 'الفدائي. إذا تم قتله (سواء في الليل من قبل المافيا أو بالإعدام في النهار)، يمكنه اختيار لاعب آخر ليقتله ويسحبه معه.', Icons.bolt, Colors.blueAccent),
            _buildRoleCard('مواطن صالح', 'الأغلبية الصامتة. لا يمتلك قدرة ليلية، وسلاحه الوحيد هو صوته وتحليله في النهار لاكتشاف المافيا.', Icons.person, Colors.grey),
            _buildRoleCard('المهرج (الجوكر)', 'المريض النفسي المستقل. لا يفوز مع المافيا ولا مع المواطنين. هدفه الوحيد أن يتم اتهامه وإعدامه في التصويت النهاري ليفوز منفرداً.', Icons.theater_comedy, Colors.purple),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontFamily: 'Cairo',
        height: 1.6,
      ),
    );
  }

  Widget _buildPhaseCard({required String title, required String description, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo', height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String name, String description, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Cairo', height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
