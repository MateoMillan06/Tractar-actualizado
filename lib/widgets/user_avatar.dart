import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/theme_provider.dart';

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
class _UserProfilePanel extends StatelessWidget {
  const _UserProfilePanel();

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
}