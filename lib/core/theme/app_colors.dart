import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette ─────────────────────────────────────────────────────────
  static const Color primary          = Color(0xFF0077B6);
  static const Color primaryLight     = Color(0xFF00B4D8);
  static const Color primaryDark      = Color(0xFF03045E);
  static const Color primaryContainer = Color(0xFFCAF0F8);

  // ── Secondary ───────────────────────────────────────────────────────────────
  static const Color secondary        = Color(0xFF48CAE4);
  static const Color accent           = Color(0xFF90E0EF);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF2EC4B6);
  static const Color warning  = Color(0xFFFF9F1C);
  static const Color error    = Color(0xFFE63946);
  static const Color info     = Color(0xFF48CAE4);

  // ── Neutrals ─────────────────────────────────────────────────────────────────
  static const Color backgroundLight  = Color(0xFFF0F9FF);
  static const Color backgroundDark   = Color(0xFF0D1B2A);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceDark      = Color(0xFF1A2636);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFF0D1B2A);
  static const Color textSecondary    = Color(0xFF4A6080);
  static const Color textHint         = Color(0xFFADB5BD);

  // ── Border & Divider ─────────────────────────────────────────────────────────
  static const Color border           = Color(0xFFDEE2E6);
  static const Color divider          = Color(0xFFEEF2F7);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F9FF), Color(0xFFCAF0F8)],
  );
}
