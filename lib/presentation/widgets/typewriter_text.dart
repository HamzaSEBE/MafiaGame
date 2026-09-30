import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'dart:async';

class TypewriterText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final VoidCallback? onFinished;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
    this.onFinished,
  });

  @override
  ConsumerState<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends ConsumerState<TypewriterText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
        if (_currentIndex % 3 == 0) {
          // play a soft tick
        }
      } else {
        timer.cancel();
        if (widget.onFinished != null) widget.onFinished!();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    return Text(_displayedText, style: widget.style);
  }
}
