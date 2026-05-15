import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class DriverVehicleSection extends StatelessWidget {
  final Map<String, dynamic>? vehicleFromTracta;

  const DriverVehicleSection({super.key, this.vehicleFromTracta});

  @override
  Widget build(BuildContext context) {
    final v = vehicleFromTracta;

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Vehículo asignado",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            if (v == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          color: Colors.white38, size: 40),
                      SizedBox(height: 10),
                      Text("No tienes vehículo asignado",
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              )
            else ...[
              _row(Icons.pin, "Placa", v["placa"] ?? "-"),
              _row(Icons.label, "Apodo",
                  v["apodo"]?.isNotEmpty == true ? v["apodo"] : "Sin apodo"),
              _row(Icons.directions_car, "Marca", v["marca"] ?? "-"),
              _row(Icons.build, "Modelo", v["modelo"] ?? "-"),
              _row(Icons.palette, "Color", v["color"] ?? "-"),
              _row(Icons.person, "Propietario", v["propietario"] ?? "-"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 15),
            const SizedBox(width: 10),
            Text("$label: ",
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}