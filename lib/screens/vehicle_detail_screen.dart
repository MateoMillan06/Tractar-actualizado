import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Map<String, dynamic>?> detailFuture;

  @override
  void initState() {
    super.initState();
    detailFuture = ApiService.getVehicleDetail(widget.vehicleId);
  }

  void refreshData() {
    setState(() {
      detailFuture = ApiService.getVehicleDetail(widget.vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: detailFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final vehicle = data["vehicle"] ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 1000,
                  child: Column(
                    children: [
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
                                subtitle: Text(vehicle["apodo"] ?? "Sin apodo"),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

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
