import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/settings/role_names_controller.dart';

import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class RoleNamesScreen extends ConsumerStatefulWidget {
  const RoleNamesScreen({super.key});

  @override
  ConsumerState<RoleNamesScreen> createState() => _RoleNamesScreenState();
}

class _RoleNamesScreenState extends ConsumerState<RoleNamesScreen> {
  bool _saving = false;
  bool _loaded = false;
  final Map<Role, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var role in Role.values) {
      _controllers[role] = TextEditingController(
        text:
            ref.read(roleNamesProvider).asData?.value[role] ??
            AppTheme.roleArabicName(role),
      );
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(roleNamesProvider.notifier).save({
        for (final role in Role.values) role: _controllers[role]!.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حفظ الأسماء: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(roleNamesProvider);
    if (!_loaded && names.hasValue) {
      _loaded = true;
      for (final role in Role.values) {
        _controllers[role]!.text =
            names.value?[role] ?? AppTheme.roleArabicName(role);
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'إعدادات الأسماء',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                    context.visual.surface,
                    context.visual.palette.backgroundEnd,
                    context.visual.background,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (names.hasError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => ref.invalidate(roleNamesProvider),
                    child: const Text('تعذر تحميل الأسماء · أعد المحاولة'),
                  ),
                ),
              if (names.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: Role.values.map((role) {
                    final color = AppTheme.roleColor(role);
                    final icon = AppTheme.roleIcon(role);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controllers[role],
                              maxLength: 80,
                              enabled: !_saving && names.hasValue,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText:
                                    'اسم الدور (${AppTheme.roleArabicName(role)})',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontFamily: 'Cairo',
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: context.visual.accent,
                                  ),
                                ),
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
                      backgroundColor: context.visual.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      shadowColor: context.visual.accent.withValues(alpha: 0.5),
                    ),
                    onPressed: _saving || names.isLoading || names.hasError
                        ? null
                        : _saveSettings,
                    child: const Text(
                      'حفظ الإعدادات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
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
