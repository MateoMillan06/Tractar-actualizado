import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final TextEditingController searchCtrl = TextEditingController();

  List<dynamic> allDrivers = [];
  List<dynamic> filteredDrivers = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDrivers();
  }

  // =========================
  // 🔄 CARGAR CONDUCTORES
  // =========================
  Future<void> loadDrivers() async {
    setState(() {
      loading = true;
    });

    final drivers = await ApiService.getDrivers();

    setState(() {
      allDrivers = drivers;
      filteredDrivers = drivers;
      loading = false;
    });
  }

  // =========================
  // 🔍 FILTRO
  // =========================
  void filterDrivers(String value) {
    setState(() {
      filteredDrivers = allDrivers.where((driver) {
        return driver["username"]
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  // =========================
  // 🚗 AFILIAR CONDUCTOR
  // =========================
  Future<void> showAssignDialog(int driverId, String status) async {
    // Bloquear si el conductor está Inactivo
    if (status == "Inactivo") {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 10),
              Text("No disponible"),
            ],
          ),
          content: const Text(
            "En estos momentos el conductor No se puede afiliar.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            ),
          ],
        ),
      );
      return;
    }
    final vehicles = await ApiService.getVehicles();
    int? selectedVehicleId;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Afiliar conductor"),
        content: DropdownButtonFormField<int>(
          items: vehicles.map((v) {
            return DropdownMenuItem<int>(
              value: v["id"],
              child: Text("${v["placa"]} - ${v["marca"]}"),
            );
          }).toList(),
          onChanged: (v) => selectedVehicleId = v,
          decoration: const InputDecoration(
            labelText: "Selecciona vehículo",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedVehicleId == null) return;

              // Punto 4: confirmación antes de afiliar
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("¿Confirmar afiliación?"),
                  content: const Text(
                    "Se afiliará este conductor al vehículo seleccionado.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Afiliar"),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              final result = await ApiService.assignDriver(
                driverId,
                selectedVehicleId!,
              );

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result["message"] ?? "Proceso completado"),
                  backgroundColor: result["success"] == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              );
              await loadDrivers();
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 900,
                    child: Column(
                      children: [
                        const Text(
                          "Gestión de conductores 👨‍✈️",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // 🔍 BUSCADOR
                        // =========================
                        LiquidGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: searchCtrl,
                              onChanged: filterDrivers,
                              decoration: const InputDecoration(
                                hintText: "Buscar conductor...",
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // LISTA
                        // =========================
                        Expanded(
                          child: filteredDrivers.isEmpty
                              ? const Center(
                                  child: Text("No hay conductores"),
                                )
                              : ListView.builder(
                                  itemCount: filteredDrivers.length,
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];

                                    final name =
                                        driver["username"] ?? "-";
                                    final status =
                                        driver["status"] ?? "Sin estado";

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: LiquidGlassCard(
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                          title: Text(name),
                                          subtitle:
                                              Text("Estado: $status"),

                                          // =========================
                                          // BOTÓN AFILIAR
                                          // =========================
                                          trailing: ElevatedButton(
                                            onPressed: () =>
                                                showAssignDialog(
                                              driver["id"],
                                              driver["status"] ?? "",
                                            ),
                                            style: (driver["status"] ?? "") == "Inactivo"
                                                ? ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.grey.shade700,
                                                    foregroundColor: Colors.white54,
                                                  )
                                                : null,
                                            child: const Text("Afiliar"),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}