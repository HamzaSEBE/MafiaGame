import 'package:flutter/material.dart';

Future<bool> confirmEndInteractiveSession(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A22),
          title: const Text(
            'إنهاء اللعبة؟',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          ),
          content: const Text(
            'سيتم إنهاء الجلسة وإخراج جميع اللاعبين من شاشة اللعبة.',
            style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'متابعة اللعبة',
                style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'إنهاء الجلسة',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
