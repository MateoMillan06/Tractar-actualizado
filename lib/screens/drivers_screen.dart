import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass_card.dart';
import 'driver_detail_screen.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getDrivers();
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = _all
          .where((d) =>
              d["username"].toString().toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Color _statusColor(String? s) {
    switch (s) {
      case "Disponible": return const Color(0xFF27AE60);
      case "En viaje":   return const Color(0xFFF39C12);
      case "Inactivo":   return const Color(0xFFE74C3C);
      default:           return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Conductores 👨‍✈️",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Buscador
                LiquidGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: const InputDecoration(
                        hintText: "Buscar conductor...",
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  color: Colors.white38, size: 48),
                              SizedBox(height: 12),
                              Text("No hay conductores",
                                  style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final d = _filtered[i];
                            final name   = d["username"] ?? "-";
                            final status = d["status"] ?? "Sin estado";
                            final initial = name.isNotEmpty
                                ? name[0].toUpperCase()
                                : "?";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LiquidGlassCard(
                                child: ListTile(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverDetailScreen(
                                        driverId: d["id"],
                                        driverName: name,
                                      ),
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF4B2E83),
                                    child: Text(initial,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text("Toca para ver detalles",
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.white38)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.15),
                                          border: Border.all(
                                              color: _statusColor(status)
                                                  .withOpacity(0.4)),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.white38, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }
}