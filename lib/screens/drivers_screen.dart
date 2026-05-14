import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final TextEditingController searchCtrl = TextEditingController();

  List<dynamic> allDrivers = [];
  List<dynamic> filteredDrivers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    setState(() => loading = true);
    final drivers = await ApiService.getDrivers();
    setState(() {
      allDrivers = drivers;
      filteredDrivers = drivers;
      loading = false;
    });
  }

  void filterDrivers(String value) {
    setState(() {
      filteredDrivers = allDrivers.where((driver) {
        return driver["username"]
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Disponible": return const Color(0xFF27AE60);
      case "En viaje":   return const Color(0xFFF39C12);
      case "Inactivo":   return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 900,
                    child: Column(
                      children: [
                        const Text(
                          "Conductores 👨‍✈️",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        LiquidGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: searchCtrl,
                              onChanged: filterDrivers,
                              decoration: const InputDecoration(
                                hintText: "Buscar conductor...",
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Expanded(
                          child: filteredDrivers.isEmpty
                              ? const Center(child: Text("No hay conductores registrados"))
                              : ListView.builder(
                                  itemCount: filteredDrivers.length,
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];
                                    final name   = driver["username"] ?? "-";
                                    final status = driver["status"] ?? "Sin estado";

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: LiquidGlassCard(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFF4B2E83),
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text("Estado: $status"),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status).withOpacity(0.18),
                                              border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
