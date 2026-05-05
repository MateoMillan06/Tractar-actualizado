import 'package:flutter/material.dart';
import '../models/session.dart';

class DriverDashboardHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const DriverDashboardHeader({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Bienvenido ${Session.username ?? ""} 🚛",
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogout,
        ),
      ],
    );
  }
}
