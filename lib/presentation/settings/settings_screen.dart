import 'package:flutter/material.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<Role, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var role in Role.values) {
      _controllers[role] = TextEditingController(text: AppTheme.roleArabicName(role));
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _saveSettings() {
    for (var role in Role.values) {
      final text = _controllers[role]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        AppTheme.customRoleNames[role] = text;
      } else {
        AppTheme.customRoleNames.remove(role);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الإعدادات بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إعدادات الأسماء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.5,
                  colors: [Color(0xFF151826), Color(0xFF0A0C13), Color(0xFF07070B)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: Role.values.map((role) {
                    final isMafia = role.toString().toLowerCase().contains('mafia');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isMafia ? Colors.redAccent.withValues(alpha: 0.2) : Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMafia ? Icons.local_fire_department : Icons.shield, 
                            color: isMafia ? Colors.redAccent : Colors.blueAccent, 
                            size: 32
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controllers[role],
                              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'اسم الدور (${AppTheme.roleArabicName(role)})',
                                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontFamily: 'Cairo'),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                      shadowColor: Colors.orangeAccent.withValues(alpha: 0.5),
                    ),
                    onPressed: _saveSettings,
                    child: const Text('حفظ الإعدادات', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
