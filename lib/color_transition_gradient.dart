import 'dart:async';

import 'package:flutter/material.dart';
 
//////////////////
///
///
///

class ColorTransitionGradient extends StatefulWidget {
  final int index;
  const ColorTransitionGradient({super.key, required this.index});

  @override
  State<ColorTransitionGradient> createState() =>
      _ColorTransitionGradientState();
}

class _ColorTransitionGradientState extends State<ColorTransitionGradient> {
  final List<Color> _colors = [
    Colors.deepPurple,
    Colors.deepPurpleAccent,
    Colors.blueAccent,
    Colors.blue
  ];

  late Timer _timer;
  int _currentColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.index % _colors.length;
    _startColorTransition();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startColorTransition() {
    const duration = Duration(seconds: 2);
    _timer = Timer.periodic(duration, (Timer timer) {
      setState(() {
        _currentColorIndex = (_currentColorIndex + 1) % _colors.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_colors[_currentColorIndex], _colors[_currentColorIndex]],
        ),
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }
}
