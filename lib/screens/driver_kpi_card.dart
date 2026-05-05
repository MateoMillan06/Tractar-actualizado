import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class DriverKpiCard extends StatelessWidget {
  final String title;
  final dynamic value;

  const DriverKpiCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LiquidGlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Column(
            children: [
              Text(
                value != null ? value.toString() : "0",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
