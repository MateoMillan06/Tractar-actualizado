import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class DriverVehicleSection extends StatelessWidget {
  final List<dynamic> vehicles;

  const DriverVehicleSection({
    super.key,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Vehículo asignado",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vehicles.isEmpty)
              const Text("No tienes vehículo asignado")
            else
              ...vehicles.map((v) => Column(
                    children: [
                      ListTile(
                        title: const Text("Placa"),
                        subtitle: Text(v["placa"] ?? "-"),
                      ),
                      ListTile(
                        title: const Text("Marca"),
                        subtitle: Text(v["marca"] ?? "-"),
                      ),
                      ListTile(
                        title: const Text("Modelo"),
                        subtitle: Text(v["modelo"] ?? "-"),
                      ),
                      ListTile(
                        title: const Text("Propietario"),
                        subtitle: Text(v["propietario"] ?? "-"),
                      ),
                      const Divider(),
                    ],
                  )),
          ],
        ),
      ),
    );
  }
}
