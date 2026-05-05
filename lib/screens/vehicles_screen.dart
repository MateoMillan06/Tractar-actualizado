import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_glass_card.dart';
import 'vehicle_detail_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
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
    final vehicles = await ApiService.getVehicles();
    setState(() {
      _all = vehicles;
      _filtered = vehicles;
      _loading = false;
    });
  }

  // Punto 6: filtrar por placa
  void _filter(String query) {
    setState(() {
      _filtered = _all.where((v) {
        final placa = v["placa"].toString().toLowerCase();
        final apodo = (v["apodo"] ?? "").toString().toLowerCase();
        final marca = (v["marca"] ?? "").toString().toLowerCase();
        return placa.contains(query.toLowerCase()) ||
            apodo.contains(query.toLowerCase()) ||
            marca.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // ── Buscador por placa ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: LiquidGlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: "Buscar por placa, marca o apodo...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),

        // ── Lista ──
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text("No se encontraron vehículos"))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final v = _filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VehicleDetailScreen(vehicleId: v["id"]),
                            ),
                          );
                          _load();
                        },
                        child: LiquidGlassCard(
                          child: ListTile(
                            leading: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                            ),
                            title: Text(v["placa"]),
                            subtitle: Text("${v["marca"]} - ${v["modelo"]}"),
                            trailing: v["apodo"] != null &&
                                    v["apodo"].toString().isNotEmpty
                                ? Text(
                                    v["apodo"].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF4B2E83),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}