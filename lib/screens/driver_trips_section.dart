import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class DriverTripsSection extends StatelessWidget {
  final List<dynamic> trips;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final Future<void> Function(int tripId, String newStatus) onUpdateStatus;

  const DriverTripsSection({
    super.key,
    required this.trips,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Mis viajes",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            DropdownButton<String>(
              value: selectedStatus,
              items: const [
                "Todos",
                "Asignado",
                "En ruta",
                "Finalizado",
                "Cancelado",
              ]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: onStatusChanged,
            ),

            const SizedBox(height: 20),

            if (trips.isEmpty)
              const Text(
                "No tienes viajes en este filtro",
              )
            else
              ...trips.map(
                (trip) => Card(
                  color: Colors.white.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.route),
                          title: Text(
                            "${trip["origen"]} → ${trip["destino"]}",
                          ),
                          subtitle: Text(
                            "Estado: ${trip["trip_status"]}\n"
                            "Vehículo: ${trip["vehiculo"]}\n"
                            "Flete: \$${trip["flete"] ?? 0}",
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (trip["trip_status"] == "Asignado")
                              ElevatedButton(
                                onPressed: () => onUpdateStatus(
                                  trip["id"],
                                  "En ruta",
                                ),
                                child: const Text("Iniciar"),
                              ),
                            if (trip["trip_status"] == "En ruta")
                              ElevatedButton(
                                onPressed: () => onUpdateStatus(
                                  trip["id"],
                                  "Finalizado",
                                ),
                                child: const Text("Finalizar"),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
