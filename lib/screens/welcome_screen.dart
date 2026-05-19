import 'package:flutter/material.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🔥 TÍTULO ARRIBA EN GLASS
              Center(
                child: SizedBox(
                  width: 520,
                  child: LiquidGlassCard(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 24,
                      ),
                      child: Text(
                        "Tractar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 🔥 BOTONES ABAJO
              SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      "Ingresar usuario",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}