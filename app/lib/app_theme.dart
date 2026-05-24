import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1C1C1C);
  static const Color card = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF00C6FF);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Netzwerk-Brandfarben — jeweils die dominante Farbe des Logos
  static const Map<String, Color> networkColors = {
    'shell': Color(0xFFFFCC00),
    'ionity': Color(0xFF7C3AED),
    'enbw': Color(0xFFEC4899),
    'aral': Color(0xFF2563EB),
    'ewe': Color(0xFF16A34A),
    'fastned': Color(0xFFF97316),
    'tesla': Color(0xFFDC2626),
    'allego': Color(0xFF0EA5E9),
    'aldi': Color(0xFF1D4ED8),
    'lidl': Color(0xFFFFCC00),
    'rewe': Color(0xFFDC2626),
    'maingau': Color(0xFF059669),
    'mer': Color(0xFF6366F1),
  };

  static const Map<String, String> networkLabels = {
    'shell': 'Shell',
    'ionity': 'IONITY',
    'enbw': 'EnBW',
    'aral': 'Aral',
    'ewe': 'EWE Go',
    'fastned': 'Fastned',
    'tesla': 'Tesla',
    'allego': 'Allego',
    'aldi': 'ALDI',
    'lidl': 'Lidl',
    'rewe': 'REWE',
    'maingau': 'Maingau',
    'mer': 'Mer',
  };

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          error: error,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary, fontSize: 18),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 16),
          titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      );
}
