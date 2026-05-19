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
      pageBuilder: (_, _, _) => const _UserProfilePanel(),
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
    final result = Session.role == "conductor"
        ? await ApiService.getDriverTractas()
        : await ApiService.getTractas();
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
                child: SingleChildScrollView(
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
                                activeThumbColor: color,
                                thumbColor: const WidgetStatePropertyAll(
                                    Colors.white),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Historial de Tractás ───────────────
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

                      const SizedBox(height: 24),

                      Divider(color: divColor),

                      const SizedBox(height: 16),

                      // ── Cerrar sesión ──────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE53935),
                                  Color(0xFFB71C1C),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _confirmLogout(context),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        size: 20, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "Cerrar sesión",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  void _confirmLogout(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "logout",
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.85 + (curved.value * 0.15),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: _LogoutConfirmDialog(
              onConfirm: () {
                Navigator.pop(ctx); // cierra diálogo
                context.read<ThemeProvider>().clearUser();
                Navigator.pop(context); // cierra panel
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
              onCancel: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
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

// ── Diálogo de confirmación de cierre de sesión ─────────────────
class _LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _LogoutConfirmDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? const Color(0xFF1B1B3A)
        : const Color(0xFF1B3A55);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "¿Cerrar sesión?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tu sesión actual se cerrará y volverás a la pantalla de inicio.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancelar",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE53935),
                                  Color(0xFFB71C1C),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onConfirm,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Center(
                                  child: Text(
                                    "Cerrar sesión",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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