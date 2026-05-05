import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class DriverPerformanceChart extends StatelessWidget {
  final Map<String, dynamic> kpis;

  const DriverPerformanceChart({
    super.key,
    required this.kpis,
  });

  Widget _buildBar(String label, int value, int total) {
    final percent = value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ($value)"),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = (kpis["active"] ?? 0) as int;
    final completed = (kpis["completed"] ?? 0) as int;
    final cancelled = (kpis["cancelled"] ?? 0) as int;

    final total = (active + completed + cancelled) == 0
        ? 1
        : active + completed + cancelled;

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Gráfica de rendimiento",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildBar("Activos", active, total),
            _buildBar("Finalizados", completed, total),
            _buildBar("Cancelados", cancelled, total),
          ],
        ),
      ),
    );
  }
}
