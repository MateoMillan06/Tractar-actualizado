import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass_card.dart';
import 'tracta_step1_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = Future.wait([
        ApiService.getVehicles(),
        ApiService.getTrips(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = snapshot.data![0] as List;
            final trips    = snapshot.data![1] as List;

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Bienvenida
                        LiquidGlassCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 28,
                              vertical: isMobile ? 16 : 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.manage_accounts,
                                    color: const Color(0xFF4B2E83),
                                    size: isMobile ? 26 : 32),
                                const SizedBox(width: 12),
                                Text(
                                  "Bienvenido, ${Session.username}",
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // KPIs
                        Row(
                          children: [
                            Expanded(
                              child: LiquidGlassCard(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 24 : 32,
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_shipping,
                                          size: isMobile ? 38 : 48,
                                          color: Colors.white),
                                      const SizedBox(height: 10),
                                      Text("${vehicles.length}",
                                          style: TextStyle(
                                              fontSize: isMobile ? 32 : 40,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      const Text("Vehículos",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LiquidGlassCard(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 24 : 32,
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.route,
                                          size: isMobile ? 38 : 48,
                                          color: Colors.white),
                                      const SizedBox(height: 10),
                                      Text("${trips.length}",
                                          style: TextStyle(
                                              fontSize: isMobile ? 32 : 40,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      const Text("Viajes",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Espacio para el FAB
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // FAB — Realizar una Tractá
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: "tracta_fab",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TractaStep1Screen()),
              );
              // Recargar home al volver de cualquier punto del flujo de tractá
              _load();
            },
            backgroundColor: const Color(0xFF4B2E83),
            icon: const Icon(Icons.local_shipping, color: Colors.white),
            label: const Text(
              "Realizar una Tractá",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}