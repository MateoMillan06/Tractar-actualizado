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

  // ── Diálogo: ¿tiene afiliación previa? ─────────────────────
  Future<void> _iniciarTracta() async {
    final afiliaciones = await ApiService.getAllAffiliations();

    if (!mounted) return;

    if (afiliaciones.isEmpty) {
      // Sin afiliaciones → flujo normal (nueva afiliación)
      return; // El usuario selecciona conductor+vehículo normalmente
    }

    // Mostrar diálogo
    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AffiliationDialog(afiliaciones: afiliaciones),
    );

    if (!mounted) return;

    if (resultado == null) {
      // Canceló o eligió nueva afiliación
      return;
    }

    // Seleccionó una afiliación existente → ir al paso 2 con pre-selección
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TractaStep2Screen(preSelectedVehicle: resultado),
      ),
    );
  }

  Future<void> _afiliar() async {
    if (conductorSeleccionado == null || vehiculoSeleccionado == null) return;

    final result = await ApiService.assignDriver(
      conductorSeleccionado!["id"],
      vehiculoSeleccionado!["id"],
    );

    if (!mounted) return;

    if (result["success"] == true) {
      // Pasar el vehículo recién afiliado para pre-seleccionarlo en el paso 2
      final preSelected = {
        "id":              vehiculoSeleccionado!["id"],
        "vehicle_id":      vehiculoSeleccionado!["id"],
        "driver_id":       conductorSeleccionado!["id"],
        "placa":           vehiculoSeleccionado!["placa"],
        "apodo":           vehiculoSeleccionado!["apodo"] ?? "",
        "driver_username": conductorSeleccionado!["username"],
      };
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TractaStep2Screen(preSelectedVehicle: preSelected),
        ),
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

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ambos = conductorSeleccionado != null && vehiculoSeleccionado != null;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStepper(),
                    const SizedBox(height: 8),

                    // Botón "¿Ya tiene afiliación?"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _iniciarTracta,
                              icon: const Icon(Icons.history, size: 16),
                              label: const Text("¿Ya tiene afiliación previa?",
                                  style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: isMobile ? _buildMobile() : _buildDesktop(),
                    ),

                    _buildActionBar(ambos),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
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
                  Text("Realizar Tractá — Paso 1",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text("Nueva afiliación conductor + vehículo",
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStepper() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _dot(1, true, "Conductor\n+ Vehículo"),
            Expanded(child: Container(height: 2, color: Colors.white24)),
            _dot(2, false, "Asignar\nViaje"),
            Expanded(child: Container(height: 2, color: Colors.white24)),
            _dot(3, false, "Tractá\nRealizada"),
          ],
        ),
      );

  Widget _buildActionBar(bool enabled) => AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: enabled ? _afiliar : null,
              icon: const Icon(Icons.link),
              label: const Text("Afiliar conductor a vehículo"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      );

  Widget _buildMobile() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Conductores", Icons.person, conductores.length),
            ..._conductoresList(),
            const SizedBox(height: 16),
            _sectionHeader("Vehículos sin afiliar", Icons.local_shipping, vehiculosSinAfiliar.length),
            ..._vehiculosList(),
            const SizedBox(height: 80),
          ],
        ),
      );

  Widget _buildDesktop() => Padding(
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
                      child: Column(children: _conductoresList()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Vehículos sin afiliar", Icons.local_shipping,
                      vehiculosSinAfiliar.length),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: _vehiculosList()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sectionHeader(String title, IconData icon, int count) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: Text("$count",
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ),
          ],
        ),
      );

  List<Widget> _conductoresList() {
    if (conductores.isEmpty) {
      return [
        LiquidGlassCard(
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text("No hay conductores registrados",
                  style: TextStyle(color: Colors.white60)),
            ),
          ),
        )
      ];
    }
    return conductores.map((c) => _conductorCard(c as Map<String, dynamic>)).toList();
  }

  List<Widget> _vehiculosList() {
    if (vehiculosSinAfiliar.isEmpty) {
      return [
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                const Text("No hay vehículos sin afiliar",
                    style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                    _load();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar vehículo"),
                ),
              ],
            ),
          ),
        )
      ];
    }
    return [
      GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width < 500 ? 2 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: vehiculosSinAfiliar
            .map((v) => _vehiculoCard(v as Map<String, dynamic>))
            .toList(),
      )
    ];
  }

  Widget _conductorCard(Map<String, dynamic> c) {
    final sel = conductorSeleccionado?["id"] == c["id"];
    return GestureDetector(
      onTap: () => setState(() => conductorSeleccionado = sel ? null : c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: sel ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          border: Border.all(
              color: sel ? Colors.green : Colors.white.withOpacity(0.12),
              width: sel ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: sel ? Colors.green : const Color(0xFF4B2E83),
              child: Icon(sel ? Icons.check : Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c["username"] ?? "-",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.green : Colors.white)),
                  Text(c["status"] ?? "-",
                      style: TextStyle(
                          fontSize: 11,
                          color: sel ? Colors.green.shade300 : Colors.white54)),
                ],
              ),
            ),
            if (sel) const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _vehiculoCard(Map<String, dynamic> v) {
    final sel = vehiculoSeleccionado?["id"] == v["id"];
    final apodo = (v["apodo"]?.toString().isNotEmpty ?? false) ? v["apodo"] : null;
    return GestureDetector(
      onTap: () => setState(() => vehiculoSeleccionado = sel ? null : v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: sel ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          border: Border.all(
              color: sel ? Colors.green : Colors.white.withOpacity(0.12),
              width: sel ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping,
                color: sel ? Colors.green : Colors.white70, size: 26),
            const SizedBox(height: 6),
            if (apodo != null)
              Text(apodo,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.green : Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Text(v["placa"] ?? "-",
                style: TextStyle(
                    fontSize: apodo != null ? 11 : 14,
                    color: sel ? Colors.green.shade300 : Colors.white60),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _dot(int n, bool active, String label) => Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.green : Colors.white12,
              border: Border.all(
                  color: active ? Colors.green : Colors.white24, width: 2),
            ),
            child: Center(
              child: Text("$n",
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9, color: active ? Colors.green : Colors.white38)),
        ],
      );
}

// ── Diálogo afiliaciones existentes ────────────────────────────
class _AffiliationDialog extends StatefulWidget {
  final List<dynamic> afiliaciones;
  const _AffiliationDialog({required this.afiliaciones});

  @override
  State<_AffiliationDialog> createState() => _AffiliationDialogState();
}

class _AffiliationDialogState extends State<_AffiliationDialog> {
  int? _selIdx;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Afiliaciones existentes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                  "Selecciona una afiliación para asignarle un viaje,\no crea una nueva.",
                  style: TextStyle(fontSize: 13, color: Colors.white60)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.afiliaciones.length,
                  itemBuilder: (_, i) {
                    final a = widget.afiliaciones[i] as Map;
                    final sel = _selIdx == i;
                    final apodo = a["apodo"]?.toString().isNotEmpty == true
                        ? a["apodo"]
                        : null;
                    return GestureDetector(
                      onTap: () => setState(() => _selIdx = sel ? null : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: sel
                              ? Colors.green.withOpacity(0.15)
                              : Colors.white.withOpacity(0.07),
                          border: Border.all(
                              color: sel
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.15),
                              width: sel ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (sel
                                        ? Colors.green
                                        : const Color(0xFF4B2E83))
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.local_shipping,
                                  color: sel ? Colors.green : Colors.white70,
                                  size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    apodo != null
                                        ? "$apodo (${a["placa"]})"
                                        : a["placa"] ?? "-",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: sel ? Colors.green : Colors.white),
                                  ),
                                  Text(
                                    "Conductor: ${a["driver_username"] ?? "-"}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: sel
                                            ? Colors.green.shade300
                                            : Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            if (sel)
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),  // nueva afiliación
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          foregroundColor: Colors.white70),
                      child: const Text("Nueva afiliación"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selIdx != null
                          ? () => Navigator.pop(
                                context,
                                widget.afiliaciones[_selIdx!] as Map<String, dynamic>,
                              )
                          : null,
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text("Usar esta"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}