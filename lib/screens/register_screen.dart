import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String? message;

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await ApiService.register(
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => message = error);
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
                        "Crear usuario",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: userCtrl,
                        decoration:
                            const InputDecoration(labelText: "Usuario"),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Usuario obligatorio"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: "Contraseña"),
                        validator: (v) =>
                            v == null || v.trim().length < 4
                                ? "Mínimo 4 caracteres"
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Confirmar contraseña",
                        ),
                        validator: (v) => v != passCtrl.text
                            ? "Las contraseñas no coinciden"
                            : null,
                      ),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            message!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: createUser,
                        child: const Text("Crear"),
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