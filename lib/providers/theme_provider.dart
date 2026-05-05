import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false; // Por defecto modo claro
  int? _currentUserId;

  bool get isDark => _isDark;

  // Clave única por usuario
  static String _key(int userId) => 'theme_user_$userId';

  // ── Cargar tema del usuario al hacer login ──────────────────
  Future<void> loadForUser(int userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key(userId)) ?? false;
    notifyListeners();
  }

  // ── Toggle — solo afecta al usuario activo ──────────────────
  Future<void> toggle() async {
    if (_currentUserId == null) return;
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_currentUserId!), _isDark);
  }

  // ── Limpiar al cerrar sesión ─────────────────────────────────
  void clearUser() {
    _currentUserId = null;
    _isDark = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // TEMAS
  // ════════════════════════════════════════════════════════════

  // Modo claro = gradiente original azul/morado, textos blancos
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4B2E83),
          secondary: Color(0xFF5DADE2),
          surface: Color(0xFF243B55),
        ),
        textTheme: const TextTheme(
          bodyLarge:   TextStyle(color: Colors.white),
          bodyMedium:  TextStyle(color: Colors.white),
          bodySmall:   TextStyle(color: Colors.white70),
          titleLarge:  TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4B2E83),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

  // Modo oscuro — más oscuro
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B4FA6),   // morado más visible sobre fondo muy oscuro
          secondary: Color(0xFF2E86AB),  // azul acento
          surface: Color(0xFF080810),
        ),
        textTheme: const TextTheme(
          bodyLarge:   TextStyle(color: Colors.white),
          bodyMedium:  TextStyle(color: Colors.white),
          bodySmall:   TextStyle(color: Colors.white70),
          titleLarge:  TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF563457),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}