import 'package:flutter/material.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class TractaSuccessScreen extends StatefulWidget {
  final int tractaNum;
  final String conductor;
  final String vehiculo;
  final String origen;
  final String destino;

  const TractaSuccessScreen({
    super.key,
    required this.tractaNum,
    required this.conductor,
    required this.vehiculo,
    required this.origen,
    required this.destino,
  });

  @override
  State<TractaSuccessScreen> createState() => _TractaSuccessScreenState();
}

class _TractaSuccessScreenState extends State<TractaSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono animado
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.2),
                            border: Border.all(color: Colors.green, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 60,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        "¡Tractá Realizada!",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "La tractá #${widget.tractaNum} se ha realizado correctamente",
                        style: TextStyle(fontSize: 15, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      LiquidGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(Icons.local_shipping, "Vehículo", widget.vehiculo),
                              const SizedBox(height: 16),
                              _infoRow(Icons.person, "Conductor", widget.conductor),
                              const SizedBox(height: 16),
                              _infoRow(Icons.trip_origin, "Desde", widget.origen),
                              const SizedBox(height: 16),
                              _infoRow(Icons.flag, "Hasta", widget.destino),

                              const SizedBox(height: 20),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Text(
                                  "La tractá #${widget.tractaNum} con conductor ${widget.conductor} "
                                  "en el vehículo ${widget.vehiculo} hacia ${widget.destino} "
                                  "desde ${widget.origen} se ha realizado correctamente.",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            // Volver al home eliminando todo el stack de tractá
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text("Ir al Inicio"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4B2E83),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4B2E83).withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
