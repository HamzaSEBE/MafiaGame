import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mafia_nightfall/presentation/auth/login_screen.dart';
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
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection('users').doc(uid).get();
      final statsDoc = await _firestore.collection('users').doc(uid).collection('stats').doc('main').get();
      
      if (mounted) {
        setState(() {
          _profileData = doc.data();
          _statsData = statsDoc.data();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 30,
      maxWidth: 250,
      maxHeight: 250,
    );
    
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        await _firestore.collection('users').doc(uid).update({'photoBase64': base64String});
        
        setState(() {
          _profileData?['photoBase64'] = base64String;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الصورة بنجاح', style: TextStyle(fontFamily: 'Cairo'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تحديث الصورة', style: TextStyle(fontFamily: 'Cairo'))),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _editName() async {
    final TextEditingController nameController = TextEditingController(text: _profileData?['displayName'] ?? '');
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('تغيير الاسم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'أدخل الاسم الجديد',
              hintStyle: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              child: const Text('حفظ', style: TextStyle(color: AppTheme.citizensPrimary, fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _auth.currentUser?.updateDisplayName(newName);
        await _firestore.collection('users').doc(uid).update({'displayName': newName});
        setState(() {
          _profileData?['displayName'] = newName;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: AppTheme.mafiaPrimary)),
      );
    }

    final user = _auth.currentUser;
    final displayName = _profileData?['displayName'] ?? 'لاعب';
    final username = _profileData?['username'] ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final gamesPlayed = _statsData?['gamesPlayed'] ?? 0;
    final mafiaWins = _statsData?['mafiaWins'] ?? 0;
    final citizenWins = _statsData?['citizenWins'] ?? 0;
    final wins = mafiaWins + citizenWins;
    final winRate = gamesPlayed > 0 ? ((wins / gamesPlayed) * 100).toStringAsFixed(1) : '0.0';

    final imageProvider = _getProfileImage();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    backgroundImage: imageProvider,
                    child: imageProvider == null 
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.textSecondary, size: 20),
                  onPressed: _editName,
                  tooltip: 'تعديل الاسم',
                ),
              ],
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
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
  }
}