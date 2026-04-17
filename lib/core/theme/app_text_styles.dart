import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle headlineLarge  = GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle headlineMedium = GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static final TextStyle headlineSmall  = GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static final TextStyle titleLarge     = GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static final TextStyle titleMedium    = GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static final TextStyle titleSmall     = GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static final TextStyle bodyLarge      = GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static final TextStyle bodyMedium     = GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static final TextStyle bodySmall      = GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static final TextStyle labelLarge     = GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static final TextStyle labelMedium    = GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static final TextStyle labelSmall     = GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
}
