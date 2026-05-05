import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          ApiService.getVehicles(),
          ApiService.getTrips(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = snapshot.data![0];
          final trips = snapshot.data![1];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 420,
                  child: LiquidGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      child: Text(
                        "Bienvenido ${Session.username} 🚛",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Center(
                    child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 48,
                    runSpacing: 24,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 220,
                        child: LiquidGlassCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                size: 52,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${vehicles.length}",
                                style: const TextStyle(fontSize: 42),
                              ),
                              const SizedBox(height: 8),
                              const Text("Vehículos"),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        height: 220,
                        child: LiquidGlassCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.route,
                                size: 52,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${trips.length}",
                                style: const TextStyle(fontSize: 42),
                              ),
                              const SizedBox(height: 8),
                              const Text("Viajes"),
                            ],
                          ),
                        ),
                  ),
                    ],
                    ),
            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}