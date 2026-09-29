import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: const Text('تعليمات اللعبة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          'قريباً.. سيتم إضافة شرح بالفيديو وتعليمات تفصيلية لكل دور هنا!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
