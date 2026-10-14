import 'package:flutter/material.dart';

/// Restrained, accessible palette for a pediatric clinical environment.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3E7975);
  static const Color primaryLight = Color(0xFF76A9A2);
  static const Color primaryDark = Color(0xFF285752);
  static const Color primaryContainer = Color(0xFFE3F0ED);
  static const Color secondary = Color(0xFF829EB0);
  static const Color accent = Color(0xFFA6B9A0);

  static const Color success = Color(0xFF43866D);
  static const Color warning = Color(0xFFB88954);
  static const Color error = Color(0xFFB85C61);
  static const Color info = Color(0xFF7296A9);

  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF172824);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF21352F);

  static const Color textPrimary = Color(0xFF263C39);
  static const Color textSecondary = Color(0xFF637773);
  static const Color textHint = Color(0xFF91A29E);
  static const Color border = Color(0xFFDEE8E3);
  static const Color divider = Color(0xFFEAF0EC);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF457E77), Color(0xFF6D9D95)],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FBF9), Color(0xFFEFF5F1)],
  );
}
