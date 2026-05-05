import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.getBilling(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return Scaffold(
          body: LiquidBackground(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "Facturación 💰",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // TOTAL
                  LiquidGlassCard(
                    child: ListTile(
                      title: const Text("Total generado"),
                      subtitle: Text("\$${data["total"]}"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MENSUAL
                  LiquidGlassCard(
                    child: ListTile(
                      title: const Text("Este mes"),
                      subtitle: Text("\$${data["monthly"]["total"]}"),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text("Por vehículo 🚛"),
                  Expanded(
                    child: ListView(
                      children: (data["by_vehicle"] as List)
                          .map(
                            (v) => ListTile(
                              title: Text(v["vehiculo"]),
                              subtitle: Text("Viajes: ${v["trips"]}"),
                              trailing: Text("\$${v["total"]}"),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text("Por conductor 👨‍✈️"),
                  Expanded(
                    child: ListView(
                      children: (data["by_driver"] as List)
                          .map(
                            (d) => ListTile(
                              title: Text(d["username"]),
                              subtitle: Text("Viajes: ${d["trips"]}"),
                              trailing: Text("\$${d["total"]}"),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}