import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _estado = "Todos";
  late Future<Map<String, dynamic>?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _reportFuture = ApiService.getReportsFiltered(
        fechaInicio: _fechaInicio != null
            ? "${_fechaInicio!.year}-${_fechaInicio!.month.toString().padLeft(2,'0')}-${_fechaInicio!.day.toString().padLeft(2,'0')}"
            : null,
        fechaFin: _fechaFin != null
            ? "${_fechaFin!.year}-${_fechaFin!.month.toString().padLeft(2,'0')}-${_fechaFin!.day.toString().padLeft(2,'0')}"
            : null,
        estado: _estado,
      );
    });
  }

  Future<void> _pickDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _fechaInicio = picked;
      } else {
        _fechaFin = picked;
      }
    });
    _load();
  }

  void _clearFilters() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _estado = "Todos";
    });
    _load();
  }

  String _fmt(DateTime? d) {
    if (d == null) return "Seleccionar";
    return "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final summary = data["summary"] ?? {};
        final trips = (data["trips"] as List?) ?? [];

        return Scaffold(
          body: LiquidBackground(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Historial y reportes 📊",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // ── Filtros ──────────────────────────────
                  LiquidGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.filter_list, size: 18,
                                  color: Colors.white70),
                              const SizedBox(width: 8),
                              const Text("Filtros",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const Spacer(),
                              if (_fechaInicio != null ||
                                  _fechaFin != null ||
                                  _estado != "Todos")
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: const Text("Limpiar"),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Punto 7: filtros por fecha
                          Row(
                            children: [
                              Expanded(
                                child: _dateButton(
                                    "Desde", _fechaInicio, () => _pickDate(true)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateButton(
                                    "Hasta", _fechaFin, () => _pickDate(false)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _stateDropdown(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Resumen KPIs ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassCard(
                          child: ListTile(
                            title: const Text("Viajes"),
                            subtitle: Text(
                                (summary["total_trips"] ?? 0).toString()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LiquidGlassCard(
                          child: ListTile(
                            title: const Text("Finalizados"),
                            subtitle: Text(
                                (summary["completed"] ?? 0).toString()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LiquidGlassCard(
                          child: ListTile(
                            title: const Text("Ingresos"),
                            subtitle: Text("\$${summary["income"] ?? 0}"),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Botón Excel ──────────────────────────
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ApiService.downloadExcel();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Excel descargado correctamente")),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Descargar Excel"),
                  ),

                  const SizedBox(height: 20),

                  // ── Lista viajes ─────────────────────────
                  Expanded(
                    child: trips.isEmpty
                        ? const Center(child: Text("No hay datos con estos filtros"))
                        : ListView.builder(
                            itemCount: trips.length,
                            itemBuilder: (context, index) {
                              final t = trips[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: LiquidGlassCard(
                                  child: ListTile(
                                    leading: const Icon(Icons.description,
                                        color: Colors.white),
                                    title: Text(
                                        "${t["origen"]} → ${t["destino"]}"),
                                    subtitle: Text(
                                      "Estado: ${t["trip_status"]}"
                                      "${t["created_at"] != null ? "\n${t["created_at"].toString().substring(0, 10)}" : ""}",
                                    ),
                                    trailing: Text("\$${t["flete"] ?? 0}"),
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
        );
      },
    );
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_fmt(date),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _estado,
          isExpanded: true,
          dropdownColor: const Color(0xFF243B55),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: const [
            "Todos", "Pendiente", "Asignado", "En ruta", "Finalizado", "Cancelado"
          ]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            setState(() => _estado = v!);
            _load();
          },
        ),
      ),
    );
  }
}