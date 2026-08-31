import 'package:flutter/material.dart';
import 'package:mafia_nightfall/data/repositories/settings_repository.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<Role, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var role in Role.values) {
      _controllers[role] = TextEditingController(text: AppTheme.roleArabicName(role));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final repo = SettingsRepository();
    final newNames = <Role, String>{};
    
    for (var role in Role.values) {
      newNames[role] = _controllers[role]!.text.trim();
    }
    
    await repo.saveCustomRoleNames(newNames);
    AppTheme.customRoleNames = newNames;
    
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح! 🎩', style: TextStyle(fontFamily: 'Cairo'))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات - تخصيص الأسماء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: Role.values.length,
        itemBuilder: (context, index) {
          final role = Role.values[index];
          final color = AppTheme.roleColor(role);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppTheme.surfaceHigh,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppTheme.roleIcon(role), color: color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppTheme.roleArabicName(role), // Current name
                          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTheme.roleAbilityDescription(role),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'Cairo', height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controllers[role],
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'الاسم الجديد',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mafiaPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('حفظ الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
