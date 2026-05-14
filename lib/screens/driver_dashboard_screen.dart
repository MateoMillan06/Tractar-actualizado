import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/user_avatar.dart';
import 'driver_affiliations_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  String selectedStatus = "Todos";
  String? selectedPlaca;
  String _statusLaboral = "Disponible";
  late Future<List<dynamic>> dashboardFuture;

  static const _purple = Color(0xFF4B2E83);
  static const _statusColors = {
    "Asignado": Color(0xFF5DADE2),
    "En ruta":  Color(0xFFF39C12),
    "Finalizado": Color(0xFF27AE60),
    "Cancelado":  Color(0xFFE74C3C),
  };

  @override
  void initState() {
    super.initState();
    loadDashboard();
    final s = Session.status ?? "Disponible";
    _statusLaboral = ["Disponible", "En viaje", "Inactivo"].contains(s) ? s : "Disponible";
  }

  void loadDashboard() {
    dashboardFuture = Future.wait([
      ApiService.getDriverDashboard(),
      ApiService.getDriverKpis(),
      ApiService.getDriverTrips(status: selectedStatus),
    ]);
  }

  Future<void> updateStatus(int tripId, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("¿Deseas ${newStatus == 'En ruta' ? 'iniciar' : 'finalizar'} este viaje?"),
        content: Text(newStatus == "En ruta"
            ? "El viaje pasará a estado En ruta."
            : "El viaje se marcará como Finalizado."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(newStatus == "En ruta" ? "Iniciar" : "Finalizar")),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ApiService.updateTripStatus(tripId, newStatus);
    if (ok) setState(() => loadDashboard());
  }

  Future<void> _changeStatusLaboral(String newStatus) async {
    final ok = await ApiService.updateDriverStatus(newStatus);
    if (ok) {
      setState(() => _statusLaboral = newStatus);
      Session.status = newStatus;
    }
  }

  // ─── KPI CARD ───────────────────────────────────────────────
  Widget _kpiCard(String label, dynamic value, IconData icon, Color color, bool isMobile) {
    return LiquidGlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 14 : 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 22),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              value != null ? value.toString() : "0",
              style: TextStyle(
                fontSize: isMobile ? 22 : 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.white.withOpacity(0.65))),
          ],
        ),
      ),
    );
  }

  // ─── PERFORMANCE BAR ────────────────────────────────────────
  Widget _perfBar(String label, int value, int total, Color color) {
    final percent = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Text("$value", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ──────────────────────────────────────────
  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  // ─── STATUS CHIP ────────────────────────────────────────────
  Widget _statusChip(String status) {
    final color = _statusColors[status] ?? Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ─── VEHICLE ROW ────────────────────────────────────────────
  Widget _vehicleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Expanded(
            child: Text(value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── VEHICLE CONTENT ────────────────────────────────────────
  Widget _vehicleContent(List<dynamic> vehicles) {
    if (vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text("No tienes vehículo asignado", style: TextStyle(color: Colors.white.withOpacity(0.6))),
      );
    }
    final placa = selectedPlaca ?? vehicles[0]["placa"].toString();
    final v = vehicles.firstWhere((v) => v["placa"].toString() == placa, orElse: () => vehicles[0]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: placa,
              dropdownColor: const Color(0xFF243B55),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              items: vehicles.map<DropdownMenuItem<String>>((v) =>
                DropdownMenuItem<String>(value: v["placa"].toString(), child: Text(v["placa"].toString()))
              ).toList(),
              onChanged: (value) => setState(() => selectedPlaca = value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _vehicleRow(Icons.pin, "Placa", v["placa"] ?? "-"),
        _vehicleRow(Icons.directions_car, "Marca", v["marca"] ?? "-"),
        _vehicleRow(Icons.build, "Modelo", v["modelo"] ?? "-"),
        _vehicleRow(Icons.person, "Propietario", v["propietario"] ?? "-"),
      ],
    );
  }

  // ─── FILTRO VIAJES ──────────────────────────────────────────
  Widget _tripFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          dropdownColor: const Color(0xFF243B55),
          style: const TextStyle(color: Colors.white),
          items: const ["Todos", "Asignado", "En ruta", "Finalizado", "Cancelado"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            setState(() { selectedStatus = value!; loadDashboard(); });
          },
        ),
      ),
    );
  }

  // ─── ESTADO LABORAL ─────────────────────────────────────────
  // Sin overflow: usa Wrap en móvil
  Widget _statusLaboralWidget(bool isMobile) {
    const statusConfig = {
      "Disponible": [Color(0xFF27AE60), Icons.check_circle_outline],
      "En viaje":   [Color(0xFFF39C12), Icons.local_shipping_outlined],
      "Inactivo":   [Color(0xFFE74C3C), Icons.do_not_disturb_on_outlined],
    };
    final currentColor = statusConfig[_statusLaboral]![0] as Color;
    final currentIcon  = statusConfig[_statusLaboral]![1] as IconData;

    final chips = ["Disponible", "En viaje", "Inactivo"].map((s) {
      final cfg      = statusConfig[s]!;
      final c        = cfg[0] as Color;
      final selected = _statusLaboral == s;
      return GestureDetector(
        onTap: () => _changeStatusLaboral(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: selected ? c : Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(s, style: TextStyle(
            color: selected ? c : Colors.white.withOpacity(0.5),
            fontSize: isMobile ? 11 : 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
        ),
      );
    }).toList();

    return LiquidGlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
        child: isMobile
            // Móvil: título arriba, chips abajo en Wrap
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(currentIcon, color: currentColor, size: 18),
                    const SizedBox(width: 8),
                    const Text("Estado laboral",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: chips),
                ],
              )
            // Desktop: todo en una fila
            : Row(
                children: [
                  Icon(currentIcon, color: currentColor, size: 20),
                  const SizedBox(width: 10),
                  const Text("Estado laboral",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const Spacer(),
                  ...chips.map((c) => Padding(padding: const EdgeInsets.only(left: 8), child: c)),
                ],
              ),
      ),
    );
  }

  // ─── TRIP CARD ──────────────────────────────────────────────
  Widget _tripCard(Map<String, dynamic> trip, bool isMobile) {
    final status = trip["trip_status"] ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _purple.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.route, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text("${trip["origen"]} → ${trip["destino"]}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                  _statusChip(status),
                ]),
                const SizedBox(height: 10),
                Text("Vehículo: ${trip["vehiculo"]}   •   Flete: \$${trip["flete"] ?? 0}",
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                if (status == "Asignado" || status == "En ruta")
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => updateStatus(trip["id"], status == "Asignado" ? "En ruta" : "Finalizado"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == "Asignado" ? const Color(0xFF5DADE2) : const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(status == "Asignado" ? "Iniciar" : "Finalizar"),
                      ),
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _purple.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.route, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${trip["origen"]} → ${trip["destino"]}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("Vehículo: ${trip["vehiculo"]}   •   Flete: \$${trip["flete"] ?? 0}",
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                  ],
                )),
                _statusChip(status),
                const SizedBox(width: 12),
                if (status == "Asignado")
                  ElevatedButton(
                    onPressed: () => updateStatus(trip["id"], "En ruta"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5DADE2), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Iniciar"),
                  ),
                if (status == "En ruta")
                  ElevatedButton(
                    onPressed: () => updateStatus(trip["id"], "Finalizado"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Finalizar"),
                  ),
              ],
            ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: FutureBuilder<List<dynamic>>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles  = (snapshot.data![0] as List?) ?? [];
            final kpis      = snapshot.data![1] as Map? ?? {};
            final trips     = (snapshot.data![2] as List?) ?? [];
            final active    = (kpis["active"]    ?? 0) as int;
            final completed = (kpis["completed"] ?? 0) as int;
            final cancelled = (kpis["cancelled"] ?? 0) as int;
            final total     = (active + completed + cancelled) == 0 ? 1 : active + completed + cancelled;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final padding  = isMobile ? 16.0 : 28.0;
                final gap      = isMobile ? 14.0 : 24.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ════════════════════════════════════
                          // HEADER — sin overflow
                          // ════════════════════════════════════
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              const UserAvatar(),
                              const SizedBox(width: 14),
                              // Título — Expanded evita desbordamiento
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Bienvenido, ${Session.username ?? ""} 🚛",
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "Panel de conductor",
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 13,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: gap),

                          // ════════════════════════════════════
                          // ESTADO LABORAL — sin overflow
                          // ════════════════════════════════════
                          _statusLaboralWidget(isMobile),

                          SizedBox(height: gap),

                          // ── Botón afiliaciones ───────────────
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const DriverAffiliationsScreen())),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text("Ver mis afiliaciones"),
                            ),
                          ),

                          SizedBox(height: gap),

                          // ════════════════════════════════════
                          // KPIs
                          // ════════════════════════════════════
                          isMobile
                              ? Column(children: [
                                  Row(children: [
                                    Expanded(child: _kpiCard("Activos", active, Icons.play_circle_outline, const Color(0xFF5DADE2), true)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _kpiCard("Finalizados", completed, Icons.check_circle_outline, const Color(0xFF27AE60), true)),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(child: _kpiCard("Cancelados", cancelled, Icons.cancel_outlined, const Color(0xFFE74C3C), true)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _kpiCard("Ingresos", "\$${kpis["income"] ?? 0}", Icons.attach_money, const Color(0xFFF39C12), true)),
                                  ]),
                                ])
                              : Row(children: [
                                  Expanded(child: _kpiCard("Activos", active, Icons.play_circle_outline, const Color(0xFF5DADE2), false)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _kpiCard("Finalizados", completed, Icons.check_circle_outline, const Color(0xFF27AE60), false)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _kpiCard("Cancelados", cancelled, Icons.cancel_outlined, const Color(0xFFE74C3C), false)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _kpiCard("Ingresos", "\$${kpis["income"] ?? 0}", Icons.attach_money, const Color(0xFFF39C12), false)),
                                ]),

                          SizedBox(height: gap),

                          // ════════════════════════════════════
                          // RENDIMIENTO + VEHÍCULO
                          // ════════════════════════════════════
                          isMobile
                              ? Column(children: [
                                  LiquidGlassCard(child: Padding(padding: const EdgeInsets.all(20),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      _sectionTitle("Rendimiento", Icons.bar_chart),
                                      _perfBar("Activos", active, total, const Color(0xFF5DADE2)),
                                      _perfBar("Finalizados", completed, total, const Color(0xFF27AE60)),
                                      _perfBar("Cancelados", cancelled, total, const Color(0xFFE74C3C)),
                                    ]),
                                  )),
                                  const SizedBox(height: 14),
                                  LiquidGlassCard(child: Padding(padding: const EdgeInsets.all(20),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      _sectionTitle("Vehículo asignado", Icons.local_shipping),
                                      _vehicleContent(vehicles),
                                    ]),
                                  )),
                                ])
                              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(flex: 5, child: LiquidGlassCard(child: Padding(padding: const EdgeInsets.all(24),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      _sectionTitle("Rendimiento", Icons.bar_chart),
                                      _perfBar("Activos", active, total, const Color(0xFF5DADE2)),
                                      _perfBar("Finalizados", completed, total, const Color(0xFF27AE60)),
                                      _perfBar("Cancelados", cancelled, total, const Color(0xFFE74C3C)),
                                    ]),
                                  ))),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 4, child: LiquidGlassCard(child: Padding(padding: const EdgeInsets.all(24),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      _sectionTitle("Vehículo asignado", Icons.local_shipping),
                                      _vehicleContent(vehicles),
                                    ]),
                                  ))),
                                ]),

                          SizedBox(height: gap),

                          // ════════════════════════════════════
                          // VIAJES
                          // ════════════════════════════════════
                          LiquidGlassCard(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  isMobile
                                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          _sectionTitle("Mis tractás", Icons.route),
                                          _tripFilter(),
                                        ])
                                      : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          _sectionTitle("Mis tractás", Icons.route),
                                          _tripFilter(),
                                        ]),
                                  SizedBox(height: isMobile ? 14 : 8),
                                  if (trips.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Center(child: Text("No tienes viajes en este filtro",
                                        style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                                    )
                                  else
                                    ...trips.map((trip) => _tripCard(trip as Map<String, dynamic>, isMobile)),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: gap),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}