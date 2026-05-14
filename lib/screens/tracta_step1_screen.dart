import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'add_vehicle_screen.dart';
import 'tracta_step2_screen.dart';

class TractaStep1Screen extends StatefulWidget {
  const TractaStep1Screen({super.key});

  @override
  State<TractaStep1Screen> createState() => _TractaStep1ScreenState();
}

class _TractaStep1ScreenState extends State<TractaStep1Screen> {
  List<dynamic> conductores = [];
  List<dynamic> vehiculosSinAfiliar = [];
  bool loading = true;

  Map<String, dynamic>? conductorSeleccionado;
  Map<String, dynamic>? vehiculoSeleccionado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final results = await Future.wait([
      ApiService.getDrivers(),
      ApiService.getVehiclesSinAfiliar(),
    ]);
    setState(() {
      conductores = results[0];
      vehiculosSinAfiliar = results[1];
      conductorSeleccionado = null;
      vehiculoSeleccionado = null;
      loading = false;
    });
  }

  Future<void> _afiliar() async {
    if (conductorSeleccionado == null || vehiculoSeleccionado == null) return;

    final result = await ApiService.assignDriver(
      conductorSeleccionado!["id"],
      vehiculoSeleccionado!["id"],
    );

    if (!mounted) return;

    if (result["success"] == true) {
      // Ir a la siguiente pantalla
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TractaStep2Screen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Error al afiliar"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _conductorCard(Map<String, dynamic> c) {
    final isSelected = conductorSeleccionado?["id"] == c["id"];
    final status = c["status"] ?? "";
    return GestureDetector(
      onTap: () => setState(() {
        conductorSeleccionado = isSelected ? null : c;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Colors.green.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? Colors.green : const Color(0xFF4B2E83),
              child: Icon(
                isSelected ? Icons.check : Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c["username"] ?? "-",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green : Colors.white,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.green.shade300 : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehiculoCard(Map<String, dynamic> v) {
    final isSelected = vehiculoSeleccionado?["id"] == v["id"];
    final apodo = (v["apodo"]?.toString().isNotEmpty ?? false) ? v["apodo"] : null;
    final placa = v["placa"] ?? "-";

    return GestureDetector(
      onTap: () => setState(() {
        vehiculoSeleccionado = isSelected ? null : v;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Colors.green.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              color: isSelected ? Colors.green : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 6),
            if (apodo != null)
              Text(
                apodo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            Text(
              placa,
              style: TextStyle(
                fontSize: apodo != null ? 12 : 15,
                fontWeight: apodo != null ? FontWeight.normal : FontWeight.bold,
                color: isSelected ? Colors.green.shade300 : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ambosSeleccionados =
        conductorSeleccionado != null && vehiculoSeleccionado != null;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Realizar Tractá — Paso 1",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Afilia un conductor a un vehículo",
                                  style: TextStyle(fontSize: 13, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Indicador de pasos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _stepDot(1, true, "Conductor\n+ Vehículo"),
                          Expanded(child: Container(height: 2, color: Colors.white24)),
                          _stepDot(2, false, "Asignar\nViaje"),
                          Expanded(child: Container(height: 2, color: Colors.white24)),
                          _stepDot(3, false, "Tractá\nRealizada"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contenido
                    Expanded(
                      child: isMobile
                          ? _buildMobile()
                          : _buildDesktop(),
                    ),

                    // Botón afiliar
                    AnimatedOpacity(
                      opacity: ambosSeleccionados ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: ambosSeleccionados ? _afiliar : null,
                            icon: const Icon(Icons.link),
                            label: const Text("Afiliar conductor a vehículo"),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _stepDot(int num, bool active, String label) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.green : Colors.white12,
            border: Border.all(
              color: active ? Colors.green : Colors.white24,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              "$num",
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: active ? Colors.green : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Conductores", Icons.person, conductores.length),
          ..._buildConductoresList(),
          const SizedBox(height: 20),
          _sectionHeader("Vehículos sin afiliar", Icons.local_shipping, vehiculosSinAfiliar.length),
          ..._buildVehiculosList(),
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
                _sectionHeader("Conductores", Icons.person, conductores.length),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: _buildConductoresList()),
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
                _sectionHeader("Vehículos sin afiliar", Icons.local_shipping, vehiculosSinAfiliar.length),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: _buildVehiculosList()),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text("$count", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConductoresList() {
    if (conductores.isEmpty) {
      return [
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                "No hay conductores registrados",
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
        ),
      ];
    }
    return conductores.map((c) => _conductorCard(c as Map<String, dynamic>)).toList();
  }

  List<Widget> _buildVehiculosList() {
    if (vehiculosSinAfiliar.isEmpty) {
      return [
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                const Text(
                  "No hay vehículos sin afiliar",
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                    );
                    _load(); // Refrescar al volver
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar vehículo"),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    // Grid de vehículos
    return [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: vehiculosSinAfiliar
            .map((v) => _vehiculoCard(v as Map<String, dynamic>))
            .toList(),
      ),
    ];
  }
}
