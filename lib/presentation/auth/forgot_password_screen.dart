import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك', style: TextStyle(fontFamily: 'Cairo'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: الرجاء التأكد من صحة البريد الإلكتروني', style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_reset, size: 80, color: AppTheme.mafiaPrimary),
              const SizedBox(height: 24),
              Text(
                'استعادة كلمة المرور',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mafiaPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('إرسال رابط إعادة التعيين', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('العودة لتسجيل الدخول', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}