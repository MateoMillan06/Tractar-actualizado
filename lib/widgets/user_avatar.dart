import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../screens/reports_screen.dart';
import '../screens/billing_screen.dart';

// ── Widget avatar reutilizable ─────────────────────────────────
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final name     = Session.username ?? "?";
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final isDriver = Session.role == "conductor";
    final color    = isDriver ? const Color(0xFF5DADE2) : const Color(0xFF4B2E83);

    return GestureDetector(
      onTap: () => _openPanel(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  void _openPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "panel",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const _UserProfilePanel(),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}

// ── Panel lateral de perfil ────────────────────────────────────
class _UserProfilePanel extends StatefulWidget {
  const _UserProfilePanel();

  @override
  State<_UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends State<_UserProfilePanel> {
  List<dynamic> _tractas = [];
  bool _loadingTractas = false;
  bool _tractasExpanded = false;

  Future<void> _loadTractas() async {
    if (_loadingTractas) return;
    setState(() { _loadingTractas = true; });
    final result = await ApiService.getTractas();
    setState(() {
      _tractas = result;
      _loadingTractas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = context.watch<ThemeProvider>().isDark;
    final name      = Session.username ?? "Usuario";
    final role      = Session.role ?? "propietario";
    final initial   = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final isDriver  = role == "conductor";
    final color     = isDriver ? const Color(0xFF5DADE2) : const Color(0xFF4B2E83);
    final roleLabel = isDriver ? "Conductor" : "Propietario";

    // ── Modo claro: panel acorde al gradiente original azul/morado
    // ── Modo oscuro: panel acorde a la paleta #161638/#302242
    final panelBg = isDark
        ? const Color(0xFF1B1B3A).withOpacity(0.92)   // muy oscuro, acorde a #161638
        : const Color(0xFF1B3A55).withOpacity(0.82);   // azul oscuro, acorde al gradiente original

    final divColor   = Colors.white.withOpacity(0.12);
    const textColor  = Colors.white;
    final subColor   = Colors.white.withOpacity(0.6);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 300,
              height: double.infinity,
              decoration: BoxDecoration(
                color: panelBg,
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Avatar grande ──────────────────────
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Nombre y rol ───────────────────────
                      Center(
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                border: Border.all(
                                    color: color.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      Divider(color: divColor),

                      const SizedBox(height: 24),

                      // ── Toggle modo ────────────────────────
                      Consumer<ThemeProvider>(
                        builder: (context, theme, _) {
                          return Row(
                            children: [
                              Icon(
                                theme.isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: subColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  theme.isDark ? "Modo oscuro" : "Modo claro",
                                  style: const TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Switch(
                                value: theme.isDark,
                                onChanged: (_) => theme.toggle(),
                                activeColor: color,
                                thumbColor: const WidgetStatePropertyAll(
                                    Colors.white),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Historial de Tractás ───────────────
                      if (Session.role != "conductor") ...[
                        Divider(color: divColor),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            setState(() => _tractasExpanded = !_tractasExpanded);
                            if (_tractasExpanded) _loadTractas();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, color: subColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Historial de Tractás",
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                  ),
                                ),
                                Icon(
                                  _tractasExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: subColor, size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_tractasExpanded) ...[
                          const SizedBox(height: 8),
                          if (_loadingTractas)
                            const Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                          else if (_tractas.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text("No hay tractás registradas",
                                style: TextStyle(color: subColor, fontSize: 12)),
                            )
                          else
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                itemCount: _tractas.length,
                                itemBuilder: (_, i) {
                                  final t = _tractas[i] as Map;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tractá #${t['id'] ?? '?'}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${t['origen'] ?? '-'} → ${t['destino'] ?? '-'}",
                                          style: const TextStyle(fontSize: 12, color: Colors.white),
                                        ),
                                        Text(
                                          "Conductor: ${t['driver'] ?? '-'}  •  Vehículo: ${t['vehiculo'] ?? '-'}",
                                          style: TextStyle(fontSize: 11, color: subColor),
                                        ),
                                        if (t['flete'] != null && t['flete'].toString().isNotEmpty)
                                          Text("Flete: \$${t['flete']}",
                                            style: TextStyle(fontSize: 11, color: subColor)),
                                        Text(
                                          "Estado: ${t['trip_status'] ?? '-'}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: (t['trip_status'] == 'Finalizado')
                                                ? Colors.green
                                                : subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                        const SizedBox(height: 4),
                      ],

                      // ── Reporte de Tractás ──────────────────
                      if (Session.role != "conductor") ...[
                        Divider(color: divColor),
                        const SizedBox(height: 4),
                        _panelNavButton(
                          context: context,
                          icon: Icons.bar_chart,
                          label: "Reporte de Tractás",
                          color: color,
                          onTap: () {
                            Navigator.pop(context); // cierra panel
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        _panelNavButton(
                          context: context,
                          icon: Icons.receipt_long,
                          label: "Facturación",
                          color: color,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BillingScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],

                      const Spacer(),

                      Divider(color: divColor),

                      const SizedBox(height: 16),

                      // ── Cambiar usuario ────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Limpiar tema del usuario al cerrar sesión
                            context.read<ThemeProvider>().clearUser();
                            Navigator.pop(context);
                            Session.userId   = null;
                            Session.username = null;
                            Session.role     = null;
                            Session.status   = null;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: divColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.switch_account,
                              size: 18, color: textColor),
                          label: const Text("Cambiar usuario",
                              style: TextStyle(color: textColor)),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}