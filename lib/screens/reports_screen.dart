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
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _future = ApiService.getReportsFiltered(
          fechaInicio: _fechaInicio != null ? _fmtApi(_fechaInicio!) : null,
          fechaFin:    _fechaFin    != null ? _fmtApi(_fechaFin!)    : null,
          estado: _estado,
        );
      });

  String _fmtApi(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";

  String _fmtDisplay(DateTime? d) {
    if (d == null) return "Seleccionar";
    return "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
  }

  Future<void> _pickDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => isInicio ? _fechaInicio = picked : _fechaFin = picked);
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

  Color _statusColor(String? s) {
    switch (s) {
      case "Asignado":   return const Color(0xFF5DADE2);
      case "En ruta":    return const Color(0xFFF39C12);
      case "Finalizado": return const Color(0xFF27AE60);
      case "Cancelado":  return const Color(0xFFE74C3C);
      default:           return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _future,
            builder: (context, snap) {
              final loading = !snap.hasData;
              final data    = snap.data ?? {};
              final summary = data["summary"] as Map? ?? {};
              final tractas = (data["trips"] as List?) ?? [];

              return Column(
                children: [
                  // ── Header ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            "Reporte de Tractás 📊",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_fechaInicio != null ||
                            _fechaFin != null ||
                            _estado != "Todos")
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text("Limpiar",
                                style: TextStyle(color: Colors.white60)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Filtros ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LiquidGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: isMobile
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _dateBtn("Desde", _fechaInicio,
                                              () => _pickDate(true))),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _dateBtn("Hasta", _fechaFin,
                                              () => _pickDate(false))),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _estadoDropdown(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                      child: _dateBtn("Desde", _fechaInicio,
                                          () => _pickDate(true))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _dateBtn("Hasta", _fechaFin,
                                          () => _pickDate(false))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _estadoDropdown()),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── KPIs ─────────────────────────────────
                  if (!loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _kpiTile("Tractás", summary["total_trips"] ?? 0,
                              Icons.route, const Color(0xFF4B2E83)),
                          const SizedBox(width: 10),
                          _kpiTile("Finalizadas", summary["completed"] ?? 0,
                              Icons.check_circle_outline, const Color(0xFF27AE60)),
                          const SizedBox(width: 10),
                          _kpiTile("Ingresos",
                              "\$${summary["income"] ?? 0}",
                              Icons.attach_money, const Color(0xFFF39C12)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Botón Excel ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Lista tractás ─────────────────────────
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : tractas.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.route_outlined,
                                        color: Colors.white38, size: 48),
                                    SizedBox(height: 12),
                                    Text("No hay tractás con estos filtros",
                                        style: TextStyle(color: Colors.white60)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: tractas.length,
                                itemBuilder: (_, i) {
                                  final t = tractas[i] as Map;
                                  final status = t["trip_status"]?.toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: LiquidGlassCard(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF4B2E83)
                                                        .withOpacity(0.25),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.route,
                                                      color: Colors.white,
                                                      size: 16),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "${t["origen"]} → ${t["destino"]}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14),
                                                  ),
                                                ),
                                                _statusBadge(status),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 16,
                                              children: [
                                                if (t["vehiculo"] != null)
                                                  _meta(Icons.local_shipping,
                                                      t["vehiculo"]),
                                                if (t["flete"] != null)
                                                  _meta(Icons.attach_money,
                                                      "\$${t["flete"]}"),
                                                if (t["created_at"] != null)
                                                  _meta(Icons.calendar_today,
                                                      t["created_at"]
                                                          .toString()
                                                          .substring(0, 10)),
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kpiTile(String label, dynamic value, IconData icon, Color color) =>
      Expanded(
        child: LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 6),
                Text(value.toString(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
        ),
      );

  Widget _dateBtn(String label, DateTime? date, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.55))),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 12, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(_fmtDisplay(date),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _estadoDropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
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

  Widget _statusBadge(String? status) {
    Color c;
    switch (status) {
      case "Asignado":   c = const Color(0xFF5DADE2); break;
      case "En ruta":    c = const Color(0xFFF39C12); break;
      case "Finalizado": c = const Color(0xFF27AE60); break;
      case "Cancelado":  c = const Color(0xFFE74C3C); break;
      default:           c = Colors.white38;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        border: Border.all(color: c.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status ?? "Pendiente",
          style: TextStyle(
              color: c, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _meta(IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white38),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      );
}