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
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; errorMsg = null; });
    try {
      final result = await ApiService.getDriverProfile(widget.driverId);
      setState(() {
        driver = result;
        loading = false;
        if (result == null) {
          errorMsg = "No se pudo cargar la información del conductor";
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header siempre visible
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Conductor: ${widget.driverName}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _load,
                      tooltip: "Recargar",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMsg != null
                        ? _errorState()
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 32,
                              vertical: 4,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 900),
                                child: isMobile
                                    ? Column(children: [
                                        _profileCard(),
                                        const SizedBox(height: 16),
                                        _vehiclesCard(),
                                        const SizedBox(height: 24),
                                      ])
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _profileCard()),
                                          const SizedBox(width: 20),
                                          Expanded(child: _vehiclesCard()),
                                        ],
                                      ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 52),
              const SizedBox(height: 16),
              Text(
                errorMsg ?? "Error desconocido",
                style: const TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );

  Widget _profileCard() {
    final d = driver!;
    final name    = d["username"]?.toString() ?? widget.driverName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final status  = d["status"]?.toString();
    final cedula  = d["cedula"]?.toString() ?? "";
    final telefono = d["telefono"]?.toString() ?? "";
    final email   = d["email"]?.toString() ?? "";

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFF4B2E83),
              child: Text(
                initial,
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _statusBadge(status),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            _fieldRow(Icons.badge, "Cédula",
                cedula.isNotEmpty ? cedula : "No registrada"),
            _fieldRow(Icons.phone, "Teléfono",
                telefono.isNotEmpty ? telefono : "No registrado"),
            _fieldRow(Icons.email, "Correo",
                email.isNotEmpty ? email : "No registrado"),
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
                const Icon(Icons.local_shipping, color: Colors.white70, size: 18),
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
                    ? v["apodo"] : null;
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
      child: Text(status ?? "Sin estado",
          style: TextStyle(
              color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _fieldRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF4B2E83), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white54)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}