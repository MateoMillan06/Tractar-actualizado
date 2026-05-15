import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import 'edit_vehicle_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _future = ApiService.getVehicleDetail(widget.vehicleId);
      });

  Color _statusColor(String? s) {
    switch (s) {
      case "Disponible": return const Color(0xFF27AE60);
      case "En viaje":   return const Color(0xFFF39C12);
      default:           return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final v        = snap.data!["vehicle"] as Map? ?? {};
            final drivers  = (snap.data!["drivers"] as List?) ?? [];

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              v["apodo"]?.isNotEmpty == true
                                  ? "${v["apodo"]} · ${v["placa"]}"
                                  : "Vehículo ${v["placa"] ?? ""}",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditVehicleScreen(vehicleId: widget.vehicleId),
                                ),
                              );
                              _load();
                            },
                            icon: const Icon(Icons.edit),
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF4B2E83)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Layout 1 o 2 columnas
                      isMobile
                          ? Column(children: [
                              _infoCard(v),
                              const SizedBox(height: 16),
                              _driversCard(drivers),
                            ])
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _infoCard(v)),
                                const SizedBox(width: 20),
                                Expanded(child: _driversCard(drivers)),
                              ],
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

  Widget _infoCard(Map v) => LiquidGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Información del vehículo", Icons.local_shipping),
              const SizedBox(height: 12),
              _infoRow(Icons.pin, "Placa", v["placa"] ?? "-"),
              _infoRow(Icons.directions_car, "Marca", v["marca"] ?? "-"),
              _infoRow(Icons.build, "Modelo", v["modelo"] ?? "-"),
              _infoRow(Icons.palette, "Color", v["color"] ?? "-"),
              _infoRow(Icons.label, "Apodo",
                  v["apodo"]?.isNotEmpty == true ? v["apodo"] : "Sin apodo"),
            ],
          ),
        ),
      );

  Widget _driversCard(List drivers) => LiquidGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                  "Conductores afiliados (${drivers.length})", Icons.people),
              const SizedBox(height: 12),
              if (drivers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text("Sin conductores afiliados",
                        style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ...drivers.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value as Map;
                  return Column(
                    children: [
                      if (i > 0) const Divider(color: Colors.white10, height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF4B2E83),
                            child: Text(
                              (d["username"]?.toString().isNotEmpty == true
                                      ? d["username"]![0]
                                      : "?")
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              d["username"] ?? "-",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(d["status"]).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _statusColor(d["status"]).withOpacity(0.4)),
                            ),
                            child: Text(
                              d["status"] ?? "-",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(d["status"]),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String t, IconData icon) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 17),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 15),
            const SizedBox(width: 10),
            Text("$label: ", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}