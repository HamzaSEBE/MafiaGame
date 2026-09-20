import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _profileData;
  PlayerStats? _userStats;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _profileData = doc.data();
      }

      final statsList = await ref.read(playerStatsRepoProvider).loadStats();
      final displayName = _profileData?['displayName'] as String? ?? '';
      
      try {
        _userStats = statsList.firstWhere((s) => s.name == displayName);
      } catch (e) {
        _userStats = PlayerStats(name: displayName);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        
        final storageRef = FirebaseStorage.instance.ref().child('avatars/\.jpg');
        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();
        
        await _auth.currentUser?.updatePhotoURL(downloadUrl);
        await _firestore.collection('users').doc(uid).update({'photoUrl': downloadUrl});
        
        setState(() {
          _profileData?['photoUrl'] = downloadUrl;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع الصورة')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('حذف الحساب', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ سيتم مسح جميع بياناتك وإحصائياتك.',
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _firestore.collection('users').doc(uid).delete();
          await _auth.currentUser?.delete();
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف الحساب: يرجى تسجيل الدخول مجدداً ثم المحاولة')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: AppTheme.mafiaPrimary)),
      );
    }

    final user = _auth.currentUser;
    final displayName = _profileData?['displayName'] as String? ?? 'مستخدم';
    final username = _profileData?['username'] as String? ?? '';
    final photoUrl = user?.photoURL ?? _profileData?['photoUrl'] as String?;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    
    final gamesPlayed = _userStats?.gamesPlayed ?? 0;
    final wins = (_userStats?.mafiaWins ?? 0) + (_userStats?.citizenWins ?? 0);
    final winRate = gamesPlayed > 0 ? ((wins / gamesPlayed) * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.surfaceHigh,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null 
                            ? Text(initial, style: const TextStyle(fontSize: 40, color: AppTheme.mafiaPrimary, fontWeight: FontWeight.bold))
                            : null,
                        ),
                        if (_isUploading)
                          const Positioned(
                            bottom: 0, left: 0, right: 0, top: 0,
                            child: CircularProgressIndicator(),
                          ),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.mafiaPrimary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  
                  // Stats Grid
                  Row(
                    children: [
                      _StatCard(title: 'المباريات', value: '$gamesPlayed', color: Colors.blue),
                      const SizedBox(width: 16),
                      _StatCard(title: 'الانتصارات', value: '$wins', color: AppTheme.citizensPrimary),
                      const SizedBox(width: 16),
                      _StatCard(title: 'نسبة الفوز', value: '$winRate%', color: Colors.amber),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceHigh,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: AppTheme.error),
                    label: const Text('حذف الحساب', style: TextStyle(fontSize: 16, color: AppTheme.error, fontFamily: 'Cairo')),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}
