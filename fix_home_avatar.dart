import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('cloud_firestore.dart')) {
    content = "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'dart:convert';\n" + content;
  }
  
  final oldHeader = """
  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    final displayName = user?.displayName ?? 'لاعب مجهول';
    final email = user?.email ?? '';

    return Padding(
""";

  final newHeader = """
  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String displayName = user.displayName ?? 'لاعب مجهول';
        String email = user.email ?? '';
        String? base64Photo;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          base64Photo = data['photoBase64'] as String?;
        }

        ImageProvider? avatarImage;
        if (base64Photo != null && base64Photo.isNotEmpty) {
          try {
            avatarImage = MemoryImage(base64Decode(base64Photo));
          } catch (_) {}
        }

        return Padding(
""";

  content = content.replaceFirst(oldHeader, newHeader);
  
  final oldAvatar = """
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.mafiaPrimary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mafiaPrimary.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: AppTheme.textSecondary),
                      ),
""";

  final newAvatar = """
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.mafiaPrimary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mafiaPrimary.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                          image: avatarImage != null ? DecorationImage(image: avatarImage, fit: BoxFit.cover) : null,
                        ),
                        child: avatarImage == null ? const Icon(Icons.person, color: AppTheme.textSecondary) : null,
                      ),
""";

  content = content.replaceFirst(oldAvatar, newAvatar);
  // Close StreamBuilder
  content = content.replaceFirst("    );\n  }\n\n  Widget _buildLuxuriousButton({", "    );\n      },\n    );\n  }\n\n  Widget _buildLuxuriousButton({");

  file.writeAsStringSync(content);
  print('Added real-time profile picture to Home Screen!');
}