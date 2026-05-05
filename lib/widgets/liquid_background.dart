import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;
  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    // Modo CLARO = gradiente original de la app
    const lightColors = [
      Color(0xFF243B55),
      Color(0xFF5DADE2),
      Color(0xFF8E7CFF),
    ];

    // Modo OSCURO — más oscuro
    const darkColors = [
      Color(0xFF080810),  // casi negro con tinte azul
      Color(0xFF0D1B2A),  // azul muy oscuro
      Color(0xFF120D1E),  // morado casi negro
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? darkColors : lightColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              "assets/images/tractar_logo_bg.png",
              width: 760,
              fit: BoxFit.contain,
            ),
          ),
          child,
        ],
      ),
    );
  }
}