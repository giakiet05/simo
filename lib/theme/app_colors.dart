import 'package:flutter/material.dart';

class AppColors {
  // Core colors
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color secondary = Color(0xFF3B82F6); // Blue 500
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  
  // Semantic colors
  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color incomeBg = Color(0xFFD1FAE5); // Emerald 100
  static const Color expense = Color(0xFFEF4444); // Red 500
  static const Color expenseBg = Color(0xFFFEE2E2); // Red 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningBg = Color(0xFFFEF3C7); // Amber 100
  static const Color info = Color(0xFF0EA5E9); // Sky 500
  static const Color infoBg = Color(0xFFE0F2FE); // Sky 100

  // Category palette (for pie charts and icons)
  static const List<Color> categoryPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
  ];
}
