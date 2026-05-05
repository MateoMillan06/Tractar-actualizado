import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'welcome_screen.dart';
import 'navigation_example.dart';
import 'driver_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? errorMessage;
  bool _obscurePass = true;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ApiService.login(
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      setState(() => errorMessage = null);

      // Cargar el tema guardado para este usuario específico
      if (!mounted) return;
      await context.read<ThemeProvider>().loadForUser(Session.userId!);
      if (!mounted) return;

      if (Session.role == "propietario") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const NavigationExample(),
          ),
        );
      } else if (Session.role == "conductor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverDashboardScreen(),
          ),
        );
      } else {
        setState(() {
          errorMessage = "Rol no reconocido";
        });
      }
    } else {
      setState(() {
        errorMessage = 'Credenciales incorrectas';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: Center(
          child: SizedBox(
            width: 460,
            child: LiquidGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WelcomeScreen(),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Ingresar',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        controller: userCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Usuario'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'El usuario es obligatorio'
                                : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La contraseña es obligatoria';
                          }
                          if (value.trim().length < 4) {
                            return 'Mínimo 4 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: login,
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}