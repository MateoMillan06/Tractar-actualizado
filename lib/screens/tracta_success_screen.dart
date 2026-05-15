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

  void _irAlHome() {
    // Vuelve al NavigationExample (home de propietarios), NO al login
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícono animado
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.15),
                            border: Border.all(color: Colors.green, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.35),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 52),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "¡Tractá Realizada!",
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 34,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "La tractá #${widget.tractaNum} se ha realizado correctamente",
                        style: const TextStyle(fontSize: 14, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Tarjeta de detalles
                      LiquidGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _infoRow(Icons.local_shipping, "Vehículo", widget.vehiculo),
                              const Divider(color: Colors.white10, height: 20),
                              _infoRow(Icons.person, "Conductor", widget.conductor),
                              const Divider(color: Colors.white10, height: 20),
                              _infoRow(Icons.trip_origin, "Desde", widget.origen),
                              const Divider(color: Colors.white10, height: 20),
                              _infoRow(Icons.flag, "Hasta", widget.destino),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mensaje resumen
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.withOpacity(0.25)),
                        ),
                        child: Text(
                          "La tractá #${widget.tractaNum} con conductor ${widget.conductor} "
                          "en el vehículo ${widget.vehiculo} hacia ${widget.destino} "
                          "desde ${widget.origen} se ha realizado correctamente.",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _irAlHome,
                          icon: const Icon(Icons.home),
                          label: const Text("Ir al Home de Propietarios"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4B2E83),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4B2E83).withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}