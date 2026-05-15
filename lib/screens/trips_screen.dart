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

  Color _statusColor(String? status) {
    switch (status) {
      case "Asignado":   return const Color(0xFF5DADE2);
      case "En ruta":    return const Color(0xFFF39C12);
      case "Finalizado": return const Color(0xFF27AE60);
      case "Cancelado":  return const Color(0xFFE74C3C);
      default:           return Colors.white38;
    }
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_outlined, color: Colors.white38, size: 52),
                SizedBox(height: 16),
                Text("No hay viajes registrados",
                    style: TextStyle(color: Colors.white60)),
                SizedBox(height: 8),
                Text(
                  "Agrega un viaje con el botón +\ny asígnalo desde \"Realizar Tractá\"",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final t = trips[index];
            final status = t["trip_status"]?.toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B2E83).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.route, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${t["origen"]} → ${t["destino"]}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (t["flete"] != null && t["flete"].toString().isNotEmpty)
                        Text(
                          "Flete: \$${t["flete"]}",
                          style: const TextStyle(
                            color: Color(0xFF4B2E83),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (status == null || status.isEmpty) ? "Pendiente" : status,
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (status != null && status != "Pendiente" && status.isNotEmpty)
                            Text(
                              "Asignado via Tractá",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
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