import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/navigation_example.dart';
import 'screens/driver_dashboard_screen.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/':       (_) => const WelcomeScreen(),
        '/login':  (_) => const LoginScreen(),
        '/home':   (_) => const NavigationExample(),
        '/driver': (_) => const DriverDashboardScreen(),
      },
    );
  }
}