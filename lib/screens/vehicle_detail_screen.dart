import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'edit_vehicle_screen.dart'; // 🔥 IMPORT NUEVO

class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState
    extends State<VehicleDetailScreen> {
  late Future<Map<String, dynamic>?> detailFuture;

  @override
  void initState() {
    super.initState();
    detailFuture = ApiService.getVehicleDetail(
      widget.vehicleId,
    );
  }

  // =========================
  // 🔄 REFRESH
  // =========================
  void refreshData() {
    setState(() {
      detailFuture = ApiService.getVehicleDetail(
        widget.vehicleId,
      );
    });
  }

  // =========================
  // ESTADO VEHÍCULO
  // =========================
  String getVehicleStatus(List<dynamic> trips) {
    for (final trip in trips) {
      final status = trip["trip_status"];

      if (status == "Asignado" || status == "En ruta") {
        return "En operación";
      }
    }
    return "Disponible";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: detailFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = snapshot.data!;

            final vehicle = data["vehicle"] ?? {};
            final driver = data["driver"];
            final trips = (data["trips"] as List?) ?? [];

            final driverName = driver?["username"];
            final driverStatus = driver?["status"];

            final status = getVehicleStatus(trips);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 1000,
                  child: Column(
                    children: [
                      // =========================
                      // HEADER
                      // =========================
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Detalle de vehículo",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // =========================
                      // INFO VEHÍCULO
                      // =========================
                      LiquidGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text("Placa"),
                                subtitle: Text(vehicle["placa"] ?? "-"),
                              ),
                              ListTile(
                                title: const Text("Marca"),
                                subtitle: Text(vehicle["marca"] ?? "-"),
                              ),
                              ListTile(
                                title: const Text("Modelo"),
                                subtitle: Text(vehicle["modelo"] ?? "-"),
                              ),
                              ListTile(
                                title: const Text("Color"),
                                subtitle: Text(vehicle["color"] ?? "-"),
                              ),
                              ListTile(
                                title: const Text("Apodo"),
                                subtitle: Text(
                                  vehicle["apodo"] ?? "Sin apodo",
                                ),
                              ),
                              ListTile(
                                title: const Text("Estado"),
                                subtitle: Text(status),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =========================
                      // CONDUCTOR
                      // =========================
                      LiquidGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                "Conductor asignado",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (driverName != null)
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(driverName),
                                  subtitle: Text(
                                    "Estado: ${driverStatus ?? "-"}",
                                  ),
                                )
                              else
                                const Text(
                                  "No hay conductor afiliado",
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =========================
                      // HISTORIAL
                      // =========================
                      LiquidGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                "Historial de viajes",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (trips.isEmpty)
                                const Text(
                                  "No hay viajes registrados",
                                )
                              else
                                ...trips.map(
                                  (trip) => Card(
                                    color: Colors.white.withOpacity(0.08),
                                    child: ListTile(
                                      leading: const Icon(Icons.route),
                                      title: Text(
                                        "${trip["origen"] ?? "-"} → ${trip["destino"] ?? "-"}",
                                      ),
                                      subtitle: Text(
                                        "Estado: ${trip["trip_status"] ?? "-"}\n"
                                        "Flete: \$${trip["flete"] ?? 0}",
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =========================
                      // 🔥 SOLO EDITAR (CORREGIDO)
                      // =========================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditVehicleScreen(
                                  vehicleId: widget.vehicleId,
                                ),
                              ),
                            );

                            // 🔥 refrescar al volver
                            refreshData();
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Editar vehículo"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}