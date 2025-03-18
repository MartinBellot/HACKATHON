import 'dart:ui';

import 'package:flutter/material.dart';

class ReportButton extends StatefulWidget {
  const ReportButton({super.key});

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.3, end: 1.7).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: ShaderMask( 
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF1aded6), Color(0xFFc05afb)],
        ).createShader(bounds),
        child: ElevatedButton(
          onPressed: () {
            debugPrint('Signalement effectué');
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(50),
            backgroundColor: Colors.white
          ),
          child: Column(
            children: [
              Icon(Icons.warning, color: Colors.black.withOpacity(0.7), size: 30),
              Text('SIGNALER', style: TextStyle(color: Colors.black.withOpacity(0.7), fontFamily: 'Roboto')),
            ])
        ),
      ),
    );
  }
}
