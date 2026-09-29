import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:mafia_nightfall/presentation/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/instructions/instructions_screen.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/profile/profile_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(audioManagerProvider).startAmbience();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF07070B), // Deep luxurious black
      body: Stack(
        children: [
          // Elegant dark background with subtle glowing gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2A1115), // Deep dark red/mahogany core
                    Color(0xFF0F0811), // Very dark purple
                    Color(0xFF07070B), // Black edge
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle noise texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/mafia_sheikh.jpg', // We can still use it faintly just for noise/texture, or omit it. Let's omit and just use pure code.
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Luxurious Header
                _buildHeader(context, ref, user),
                
                const Spacer(flex: 2),
                
                // Glowing Logo & Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mafiaAccent.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(color: AppTheme.mafiaAccent.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.theater_comedy, // Or any elegant icon, local asset is better if we had one
                          size: 70,
                          color: AppTheme.mafiaAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مافيا عالشوارب',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          letterSpacing: -1,
                          shadows: [
                            Shadow(color: AppTheme.mafiaAccent.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'البقاء للأذكى',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontFamily: 'Cairo',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Primary Interactive Mode Button
                      _buildGameModeCard(
                        context: context,
                        ref: ref,
                        title: 'لعب تفاعلي',
                        subtitle: 'يمسح كل لاعب الكود من هاتفه',
                        icon: Icons.qr_code_scanner,
                        isPrimary: true,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: true)));
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Secondary Offline Mode Button
                      _buildGameModeCard(
                        context: context,
                        ref: ref,
                        title: 'لعب محلي',
                        subtitle: 'تمرير جهاز واحد بين جميع اللاعبين',
                        icon: Icons.phone_android,
                        isPrimary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: false)));
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Hype Online Button
                      _buildOnlineTeaser(context, ref),
                      
                      const SizedBox(height: 24),
                      
                      // Secondary Actions Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.leaderboard,
                              label: 'الإحصائيات',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.history_edu,
                              label: 'السجل',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GameHistoryScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.menu_book,
                              label: 'التعليمات',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Settings Button
                IconButton(
                  onPressed: () {
                    ref.read(audioManagerProvider).playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  splashRadius: 24,
                ),
                const Spacer(),
                
                // Profile Info
                GestureDetector(
                  onTap: () {
                    ref.read(audioManagerProvider).playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 14,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontFamily: 'Cairo',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

    Widget _buildGameModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF4A0000)], // Deep Mafia Red
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isPrimary ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: isPrimary ? 1.5 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineTeaser(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(audioManagerProvider).playClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نعمل على إضافة هذه الميزة قريباً! 🔥', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Color(0xFF8B0000),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF15101A), // Dark purple/black tint
          border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.public, color: Colors.deepPurpleAccent.withValues(alpha: 0.3), size: 36),
                const Icon(Icons.public, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'أونلاين',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'قريباً 🔥',
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'العب مع أصدقائك عن بُعد',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}