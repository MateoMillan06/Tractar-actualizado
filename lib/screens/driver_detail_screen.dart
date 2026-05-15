import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class DriverDetailScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  const DriverDetailScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  Map<String, dynamic>? driver;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final result = await ApiService.getDriverProfile(widget.driverId);
    setState(() {
      driver = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
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
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Conductor: ${widget.driverName}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          isMobile
                              ? Column(children: [
                                  _profileCard(),
                                  const SizedBox(height: 16),
                                  _vehiclesCard(),
                                ])
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _profileCard()),
                                    const SizedBox(width: 20),
                                    Expanded(child: _vehiclesCard()),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _profileCard() {
    if (driver == null) return const SizedBox.shrink();
    final d = driver!;
    final initial = (d["username"]?.toString().isNotEmpty == true)
        ? d["username"]![0].toUpperCase()
        : "?";

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF4B2E83),
              child: Text(
                initial,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              d["username"] ?? "-",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _statusBadge(d["status"]),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            _fieldRow(Icons.badge, "Cédula",
                d["cedula"]?.toString().isNotEmpty == true ? d["cedula"] : "No registrada"),
            _fieldRow(Icons.phone, "Teléfono",
                d["telefono"]?.toString().isNotEmpty == true ? d["telefono"] : "No registrado"),
            _fieldRow(Icons.email, "Correo",
                d["email"]?.toString().isNotEmpty == true ? d["email"] : "No registrado"),
          ],
        ),
      ),
    );
  }

  Widget _vehiclesCard() {
    final vehicles = (driver?["vehicles"] as List?) ?? [];

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white70, size: 17),
                const SizedBox(width: 8),
                Text(
                  "Vehículos afiliados (${vehicles.length})",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (vehicles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          color: Colors.white38, size: 40),
                      SizedBox(height: 10),
                      Text("Sin vehículos afiliados",
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              )
            else
              ...vehicles.asMap().entries.map((e) {
                final i = e.key;
                final v = e.value as Map;
                final apodo = v["apodo"]?.toString().isNotEmpty == true
                    ? v["apodo"]
                    : null;
                return Column(
                  children: [
                    if (i > 0) const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B2E83).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apodo != null
                                    ? "$apodo · ${v["placa"]}"
                                    : v["placa"] ?? "-",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${v["marca"] ?? ""} ${v["modelo"] ?? ""} · ${v["color"] ?? ""}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white54),
                              ),
                            ],
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
  }

  Widget _statusBadge(String? status) {
    Color c;
    switch (status) {
      case "Disponible": c = const Color(0xFF27AE60); break;
      case "En viaje":   c = const Color(0xFFF39C12); break;
      default:           c = Colors.white38;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        border: Border.all(color: c.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status ?? "-",
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _fieldRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white38, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}