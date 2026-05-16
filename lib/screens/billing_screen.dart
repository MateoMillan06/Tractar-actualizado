import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getBilling(),
            builder: (context, snap) {
              final loading = !snap.hasData;
              final data    = snap.data ?? {};

              final total     = data["total"] ?? 0;
              final monthly   = (data["monthly"] as Map?) ?? {};
              final byVehicle = (data["by_vehicle"] as List?) ?? [];
              final byDriver  = (data["by_driver"] as List?) ?? [];

              return Column(
                children: [
                  // ── Header ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Facturación",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 28,
                              vertical: 4,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 900),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // ── KPIs grandes ───────────────
                                    isMobile
                                        ? Column(children: [
                                            _bigKpi("Total generado",
                                                "\$$total",
                                                Icons.account_balance_wallet,
                                                const Color(0xFF4B2E83)),
                                            const SizedBox(height: 12),
                                            _bigKpi(
                                                "Este mes",
                                                "\$${monthly["total"] ?? 0}",
                                                Icons.calendar_month,
                                                const Color(0xFF27AE60)),
                                          ])
                                        : Row(children: [
                                            Expanded(
                                                child: _bigKpi(
                                                    "Total generado",
                                                    "\$$total",
                                                    Icons.account_balance_wallet,
                                                    const Color(0xFF4B2E83))),
                                            const SizedBox(width: 16),
                                            Expanded(
                                                child: _bigKpi(
                                                    "Este mes",
                                                    "\$${monthly["total"] ?? 0}",
                                                    Icons.calendar_month,
                                                    const Color(0xFF27AE60))),
                                          ]),

                                    const SizedBox(height: 20),

                                    // ── Por vehículo ───────────────
                                    _sectionHeader(
                                        "Por vehículo", byVehicle.length),
                                    const SizedBox(height: 10),
                                    if (byVehicle.isEmpty)
                                      _emptyState("Sin datos de vehículos")
                                    else
                                      ...byVehicle
                                          .map((v) => _billingRow(
                                                icon: Icons.local_shipping,
                                                title: v["vehiculo"]
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true
                                                    ? v["vehiculo"]
                                                    : "Sin nombre",
                                                subtitle:
                                                    "${v["trips"]} tractá(s)",
                                                amount: "\$${v["total"] ?? 0}",
                                                color: const Color(0xFF4B2E83),
                                              ))
                                          .toList(),

                                    const SizedBox(height: 20),

                                    // ── Por conductor ──────────────
                                    _sectionHeader(
                                        "Por conductor", byDriver.length),
                                    const SizedBox(height: 10),
                                    if (byDriver.isEmpty)
                                      _emptyState("Sin datos de conductores")
                                    else
                                      ...byDriver
                                          .map((d) => _billingRow(
                                                icon: Icons.person,
                                                title: d["username"]
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true
                                                    ? d["username"]
                                                    : "Sin nombre",
                                                subtitle:
                                                    "${d["trips"]} tractá(s)",
                                                amount: "\$${d["total"] ?? 0}",
                                                color: const Color(0xFF27AE60),
                                              ))
                                          .toList(),

                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _bigKpi(String label, String value, IconData icon, Color color) =>
      LiquidGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, int count) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10)),
            child: Text("$count",
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ),
        ],
      );

  Widget _billingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                Text(amount,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ),
      );

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
}