import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'add_trip_screen.dart';
import 'tracta_step1_screen.dart';
import 'tracta_success_screen.dart';

class TractaStep2Screen extends StatefulWidget {
  final Map<String, dynamic>? preSelectedVehicle;

  const TractaStep2Screen({super.key, this.preSelectedVehicle});

  @override
  State<TractaStep2Screen> createState() => _TractaStep2ScreenState();
}

class _TractaStep2ScreenState extends State<TractaStep2Screen> {
  // En el paso 2 siempre mostramos TODAS las afiliaciones conductor+vehículo
  List<dynamic> afiliaciones = [];
  List<dynamic> viajesSinAsignar = [];
  bool loading = true;

  Map<String, dynamic>? afiliacionSeleccionada;
  Map<String, dynamic>? viajeSeleccionado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final results = await Future.wait([
      ApiService.getVehiclesAfiliados(),
      ApiService.getTripsSinAsignar(),
    ]);
    if (!mounted) return;
    setState(() {
      afiliaciones = results[0];
      viajesSinAsignar = results[1];
      viajeSeleccionado = null;
      loading = false;
    });
    // Pre-seleccionar afiliación si viene del diálogo
    if (widget.preSelectedVehicle != null && afiliaciones.isNotEmpty) {
      final preVehicleId = widget.preSelectedVehicle!["vehicle_id"] ??
                           widget.preSelectedVehicle!["id"];
      final preDriverId  = widget.preSelectedVehicle!["driver_id"];
      final match = afiliaciones.firstWhere(
        (a) => a["id"] == preVehicleId ||
               (a["driver_id"] == preDriverId && a["id"] == preVehicleId),
        orElse: () => null,
      );
      if (match != null && mounted) {
        setState(() => afiliacionSeleccionada = match as Map<String, dynamic>);
      }
    }
  }

  Future<void> _realizarTracta() async {
    if (afiliacionSeleccionada == null || viajeSeleccionado == null) return;

    final driverId  = afiliacionSeleccionada!["driver_id"] as int?;
    final vehicleId = afiliacionSeleccionada!["id"] as int?;
    final tripId    = viajeSeleccionado!["id"] as int?;

    if (driverId == null || vehicleId == null || tripId == null) return;

    final result = await ApiService.assignTrip(
      tripId: tripId,
      driverId: driverId,
      vehicleId: vehicleId,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TractaSuccessScreen(
            tractaNum: tripId,
            conductor: afiliacionSeleccionada!["driver_username"] ?? "Conductor",
            vehiculo: (afiliacionSeleccionada!["apodo"]?.isNotEmpty == true)
                ? afiliacionSeleccionada!["apodo"]
                : afiliacionSeleccionada!["placa"],
            origen: viajeSeleccionado!["origen"] ?? "-",
            destino: viajeSeleccionado!["destino"] ?? "-",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Error al realizar la tractá"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _afiliacionCard(Map<String, dynamic> v) {
    final isSelected = afiliacionSeleccionada?["id"] == v["id"];
    final apodo  = (v["apodo"]?.toString().isNotEmpty ?? false) ? v["apodo"] : null;
    final placa  = v["placa"] ?? "-";
    final driver = v["driver_username"] ?? "Sin conductor";

    return GestureDetector(
      onTap: () => setState(() {
        afiliacionSeleccionada = isSelected ? null : v;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.green.withOpacity(0.18) : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping,
                    color: isSelected ? Colors.green : Colors.white70, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (apodo != null)
                        Text(apodo,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isSelected ? Colors.green : Colors.white)),
                      Text(placa,
                          style: TextStyle(
                              fontSize: apodo != null ? 12 : 15,
                              color: isSelected ? Colors.green.shade300 : Colors.white70)),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(driver, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _viajeCard(Map<String, dynamic> t) {
    final isSelected = viajeSeleccionado?["id"] == t["id"];

    return GestureDetector(
      onTap: () => setState(() {
        viajeSeleccionado = isSelected ? null : t;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.green.withOpacity(0.18) : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSelected ? Colors.green : const Color(0xFF4B2E83)).withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.route,
                  color: isSelected ? Colors.green : Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${t["origen"]} → ${t["destino"]}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.green : Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (t["flete"] != null && t["flete"].toString().isNotEmpty)
                    Text("Flete: \$${t["flete"]}",
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.green.shade300 : Colors.white54)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ambos = afiliacionSeleccionada != null && viajeSeleccionado != null;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const TractaStep1Screen()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Realizar Tractá — Paso 2",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Asigna un viaje al conductor con vehículo",
                                    style: TextStyle(fontSize: 13, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildStepper(),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: isMobile ? _buildMobile() : _buildDesktop(),
                    ),

                    AnimatedOpacity(
                      opacity: ambos ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: ambos ? _realizarTracta : null,
                            icon: const Icon(Icons.local_shipping),
                            label: const Text("Realizar Tractá"),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepDot(1, false, "Conductor\n+ Vehículo", done: true),
        Expanded(child: Container(height: 2, color: Colors.green)),
        _stepDot(2, true, "Asignar\nViaje"),
        Expanded(child: Container(height: 2, color: Colors.white24)),
        _stepDot(3, false, "Tractá\nRealizada"),
      ],
    );
  }

  Widget _stepDot(int num, bool active, String label, {bool done = false}) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? Colors.green.withOpacity(0.3)
                : active ? Colors.green : Colors.white12,
            border: Border.all(
              color: done || active ? Colors.green : Colors.white24, width: 2),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text("$num",
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: active ? Colors.green : Colors.white38)),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Afiliaciones (Conductor + Vehículo)", Icons.link, afiliaciones.length),
          ..._buildAfiliacionesList(),
          const SizedBox(height: 20),
          _sectionHeader("Viajes disponibles", Icons.route, viajesSinAsignar.length),
          ..._buildViajesList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Afiliaciones\n(Conductor + Vehículo)", Icons.link, afiliaciones.length),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: _buildAfiliacionesList()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Viajes disponibles", Icons.route, viajesSinAsignar.length),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: _buildViajesList()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Text("$count",
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAfiliacionesList() {
    if (afiliaciones.isEmpty) {
      return [
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.link_off, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                const Text("No hay afiliaciones conductor+vehículo.\nVe al Paso 1.",
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TractaStep1Screen()),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Ir al Paso 1"),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return afiliaciones.map((v) => _afiliacionCard(v as Map<String, dynamic>)).toList();
  }

  List<Widget> _buildViajesList() {
    if (viajesSinAsignar.isEmpty) {
      return [
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.route_outlined, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                const Text("No hay viajes sin asignar",
                    style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddTripScreen()),
                    );
                    _load();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar viaje"),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return viajesSinAsignar.map((t) => _viajeCard(t as Map<String, dynamic>)).toList();
  }
}