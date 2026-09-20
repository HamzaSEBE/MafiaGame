import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/stats/stats_screen.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/profile/profile_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          _profileData = doc.data();
        });
      }
    }
  }

  ImageProvider? _getProfileImage() {
    final base64String = _profileData?['photoBase64'] as String?;
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _profileData?['displayName'] ?? 'Ù„Ø§Ø¹Ø¨';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final imageProvider = _getProfileImage();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          const AnimatedBackground(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                          .then((_) => _loadProfile()); // Reload if changed
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.surfaceHigh,
                          backgroundImage: imageProvider,
                          child: imageProvider == null 
                            ? Text(initial, style: const TextStyle(fontSize: 20, color: AppTheme.mafiaPrimary, fontWeight: FontWeight.bold))
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Ù…Ø±Ø­Ø¨Ø§Ù‹ Ø¨ÙƒØŒ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
                            Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80), 
                  // Premium Mafia Logo Area
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.mafiaPrimary.withValues(alpha: 0.6),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppTheme.surface.withValues(alpha: 0.8),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/mafia_sheikh.jpg'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: AppTheme.mafiaPrimary, width: 3),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ù…Ø§ÙÙŠØ§\nØ¹Ø§Ù„Ø´ÙˆØ§Ø±Ø¨',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: AppTheme.mafiaPrimary.withValues(alpha: 0.8),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 64),
                  _buildMenuButton(ref, context,
                    title: 'Ù„Ø¹Ø¨Ø© Ø¬Ø¯ÙŠØ¯Ø©',
                    icon: Icons.play_arrow_rounded,
                    color: AppTheme.mafiaPrimary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen())),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(ref, context,
                    title: 'Ø³Ø¬Ù„ Ø§Ù„Ù…Ø¨Ø§Ø±ÙŠØ§Øª',
                    icon: Icons.history_rounded,
                    color: AppTheme.surfaceHigh,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameHistoryScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(ref, context,
                    title: 'Ø§Ù„Ø¥Ø­ØµØ§Ø¦ÙŠØ§Øª ÙˆØ§Ù„Ø£Ù„Ù‚Ø§Ø¨',
                    icon: Icons.leaderboard_rounded,
                    color: AppTheme.surfaceHigh,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(WidgetRef ref, 
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Play sound asynchronously without awaiting
            ref.read(audioManagerProvider).playClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isPrimary ? 22 : 18,
                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}