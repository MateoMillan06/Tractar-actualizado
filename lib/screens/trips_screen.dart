import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass_card.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<dynamic>> tripsFuture;

  @override
  void initState() {
    super.initState();
    tripsFuture = ApiService.getTrips();
  }

  Future<void> refreshTrips() async {
    setState(() {
      tripsFuture = ApiService.getTrips();
    });
  }

  Future<void> showAssignDialog(Map<String, dynamic> trip) async {
    final drivers = await ApiService.getDrivers();
    final vehicles = await ApiService.getVehicles();

    int? selectedDriverId;
    int? selectedVehicleId;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Asignar viaje"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Conductor"),
              items: drivers
                  .map(
                    (d) => DropdownMenuItem<int>(
                      value: d["id"],
                      child: Text(d["username"]),
                    ),
                  )
                  .toList(),
              onChanged: (v) => selectedDriverId = v,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Vehículo"),
              items: vehicles
                  .map(
                    (v) => DropdownMenuItem<int>(
                      value: v["id"],
                      child: Text(v["placa"]),
                    ),
                  )
                  .toList(),
              onChanged: (v) => selectedVehicleId = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedDriverId == null || selectedVehicleId == null) return;

              // Punto 4: confirmación antes de asignar
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("¿Confirmar asignación?"),
                  content: const Text(
                    "Se asignará el conductor y vehículo seleccionados a este viaje.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Asignar"),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              final result = await ApiService.assignTrip(
                tripId: trip["id"],
                driverId: selectedDriverId!,
                vehicleId: selectedVehicleId!,
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
              if (result["success"] == true) refreshTrips();
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // 🔥 BOTÓN INTELIGENTE
  Widget _buildTripAction(Map<String, dynamic> trip) {
    final status = trip["trip_status"];

    if (status == "Asignado" ||
        status == "En ruta" ||
        status == "Finalizado") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Este viaje ya se ha asignado",
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => showAssignDialog(trip),
      icon: const Icon(Icons.assignment),
      label: const Text("Asignar"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4B2E83),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: tripsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data!;

        if (trips.isEmpty) {
          return const Center(child: Text("No hay viajes"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final t = trips[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 TITULO
                      Text(
                        "${t["origen"]} → ${t["destino"]}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Vehículo: ${t["vehiculo"] ?? "Sin asignar"}",
                      ),
                      Text(
                        "Estado: ${t["trip_status"] ?? "Pendiente"}",
                      ),

                      if (t["flete"] != null &&
                          t["flete"].toString().isNotEmpty)
                        Text(
                          "Flete: \$${t["flete"]}",
                          style: const TextStyle(
                            color: Color(0xFF4B2E83),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 🔥 ACCIÓN
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildTripAction(t),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}