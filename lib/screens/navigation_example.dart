import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/session.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/user_avatar.dart';
import 'home_screen.dart';
import 'vehicles_screen.dart';
import 'trips_screen.dart';
import 'drivers_screen.dart';
import 'reports_screen.dart';
import 'billing_screen.dart';
import 'add_vehicle_screen.dart';
import 'add_trip_screen.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int index = 0;
  int refreshTick = 0;

  Future<void> _goToAddVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
    if (!mounted) return;
    setState(() => refreshTick++);
  }

  Future<void> _goToAddTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTripScreen()),
    );
    if (!mounted) return;
    setState(() => refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    // Iconos y labels siempre blancos — fondo siempre oscuro en ambos modos
    const iconColor  = Colors.white;
    const labelColor = Colors.white;
    const navColor   = Color(0xFF4B2E83); // solo para el indicador seleccionado

    final screens = [
      HomeScreen(key: ValueKey(refreshTick)),
      VehiclesScreen(key: ValueKey('v$refreshTick')),
      TripsScreen(key: ValueKey('t$refreshTick')),
      const DriversScreen(),
      const ReportsScreen(),
      const BillingScreen(),
    ];

    // ── AppBar adaptativo ──────────────────────────────────
    final appBar = AppBar(
      toolbarHeight: isMobile ? 70 : 92,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: isMobile ? 12 : 20,
      title: Row(
        children: [
          // Avatar con panel de perfil
          const UserAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: LiquidGlassCard(
              radius: 20,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 20,
                  vertical: isMobile ? 10 : 14,
                ),
                child: Text(
                  "Tractar • ${Session.username}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // ── Barra de navegación adaptativa ────────────────────
    // Móvil: solo muestra label de la pestaña activa
    final bottomNav = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.white.withOpacity(0.08),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withOpacity(0.18),
            labelBehavior: isMobile
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: const WidgetStatePropertyAll(
              TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            height: isMobile ? 64 : null,
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: iconColor),
                selectedIcon: Icon(Icons.home, color: iconColor),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined, color: iconColor),
                selectedIcon: Icon(Icons.local_shipping, color: iconColor),
                label: "Vehículos",
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined, color: iconColor),
                selectedIcon: Icon(Icons.route, color: iconColor),
                label: "Viajes",
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline, color: iconColor),
                selectedIcon: Icon(Icons.people, color: iconColor),
                label: "Conductores",
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, color: iconColor),
                selectedIcon: Icon(Icons.bar_chart, color: iconColor),
                label: "Reportes",
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: iconColor),
                selectedIcon: Icon(Icons.receipt_long, color: iconColor),
                label: "Facturación",
              ),
            ],
          ),
        ),
      ),
    );

    // ── FAB adaptativo ─────────────────────────────────────
    // Móvil: solo icono — Desktop: icono + texto
    final fab = index == 1
        ? isMobile
            ? FloatingActionButton(
                onPressed: _goToAddVehicle,
                child: const Icon(Icons.add),
              )
            : FloatingActionButton.extended(
                onPressed: _goToAddVehicle,
                label: const Text("Agregar vehículo"),
              )
        : index == 2
            ? isMobile
                ? FloatingActionButton(
                    onPressed: _goToAddTrip,
                    child: const Icon(Icons.add),
                  )
                : FloatingActionButton.extended(
                    onPressed: _goToAddTrip,
                    label: const Text("Agregar viaje"),
                  )
            : null;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: LiquidBackground(
        child: SafeArea(child: screens[index]),
      ),
      bottomNavigationBar: bottomNav,
      floatingActionButton: fab,
    );
  }
}