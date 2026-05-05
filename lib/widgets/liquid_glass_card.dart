import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const LiquidGlassCard({super.key, required this.child, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}