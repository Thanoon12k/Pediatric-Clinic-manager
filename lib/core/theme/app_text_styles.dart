import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  static final TextStyle headlineLarge = GoogleFonts.tajawal(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static final TextStyle headlineMedium = GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static final TextStyle headlineSmall = GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle titleLarge = GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle titleMedium = GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle titleSmall = GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle bodyLarge = GoogleFonts.tajawal(fontSize: 16, color: AppColors.textPrimary);
  static final TextStyle bodyMedium = GoogleFonts.tajawal(fontSize: 14, color: AppColors.textPrimary);
  static final TextStyle bodySmall = GoogleFonts.tajawal(fontSize: 13, color: AppColors.textSecondary);
  static final TextStyle labelLarge = GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static final TextStyle labelMedium = GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static final TextStyle labelSmall = GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
}
