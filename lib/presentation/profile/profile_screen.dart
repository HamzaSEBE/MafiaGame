import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';
import 'dart:convert';
import 'package:mafia_nightfall/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() => _profileData = doc.data());
      }

      final statsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('career')
          .get();
      if (!mounted) return;
      if (statsDoc.exists) {
        setState(() => _statsData = statsDoc.data());
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        await ref.read(profileRepositoryProvider).saveAvatar(user.uid, bytes);
        await _loadProfileData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('فشل تحديث الصورة')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  ImageProvider? _getProfileImage() {
    final stored = ref.watch(profileAvatarProvider).asData?.value;
    if (stored != null) return MemoryImage(stored);
    if (_profileData != null &&
        (_profileData!['photoBase64'] ?? _profileData!['avatarBase64']) !=
            null) {
      try {
        return MemoryImage(
          base64Decode(
            (_profileData!['photoBase64'] ?? _profileData!['avatarBase64']),
          ),
        );
      } catch (_) {}
    }
    return null;
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _profileData?['displayName'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.visual.surface,
        title: const Text(
          'تعديل الاسم',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'الاسم الجديد',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.visual.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.visual.accent,
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).update({
                    'displayName': nameController.text.trim(),
                  });
                  await user.updateDisplayName(nameController.text.trim());
                  _loadProfileData();
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.5,
                  colors: [
                    context.visual.palette.cardEnd,
                    context.visual.surface,
                    context.visual.background,
                  ],
                ),
              ),
            ),
          ),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.visual.accent,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar Section
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: context.visual.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.black45,
                                backgroundImage: _getProfileImage(),
                                child: _getProfileImage() == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white54,
                                      )
                                    : null,
                              ),
                            ),
                            if (_isUploading)
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  color: context.visual.accent,
                                ),
                              ),
                            GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.visual.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name and Username
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _profileData?['displayName'] ?? 'لاعب',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 20,
                              color: context.visual.accent,
                            ),
                            onPressed: _showEditNameDialog,
                          ),
                        ],
                      ),
                      Text(
                        '@${_profileData?['username'] ?? 'user'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Glassmorphic Stats Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إحصائيات الجولات التي أدرتها',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.visual.accent,
                                fontFamily: 'Cairo',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Divider(color: Colors.white10, height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'لعب',
                                  _statsData?['gamesPlayed']?.toString() ?? '0',
                                  Icons.sports_esports,
                                  Colors.white,
                                ),
                                _buildStatItem(
                                  'فوز مافيا',
                                  _statsData?['mafiaWins']?.toString() ?? '0',
                                  Icons.local_fire_department,
                                  Colors.redAccent,
                                ),
                                _buildStatItem(
                                  'فوز مواطنين',
                                  _statsData?['citizenWins']?.toString() ?? '0',
                                  Icons.shield,
                                  Colors.blueAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email, color: Colors.white54),
                            const SizedBox(width: 16),
                            Text(
                              _profileData?['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
