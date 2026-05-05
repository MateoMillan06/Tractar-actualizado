import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

// Punto 5: pantalla de afiliaciones del conductor
class DriverAffiliationsScreen extends StatelessWidget {
  const DriverAffiliationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LiquidBackground(
        child: FutureBuilder<List<dynamic>>(
          future: ApiService.getDriverAffiliations(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final affiliations = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mis afiliaciones 🔗",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Vehículos a los que estás afiliado",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (affiliations.isEmpty)
                        LiquidGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.link_off,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.4)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No tienes afiliaciones activas",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...affiliations.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: LiquidGlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4B2E83)
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a["placa"] ?? "-",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${a["marca"]} ${a["modelo"]} • ${a["color"]}",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.person,
                                                    size: 13,
                                                    color: Colors.white
                                                        .withOpacity(0.5)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Propietario: ${a["propietario"]}",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF27AE60)
                                              .withOpacity(0.15),
                                          border: Border.all(
                                              color: const Color(0xFF27AE60)
                                                  .withOpacity(0.5)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "Activo",
                                          style: TextStyle(
                                            color: Color(0xFF27AE60),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}