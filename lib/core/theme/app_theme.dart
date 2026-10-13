import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final foreground = dark ? const Color(0xFFEAF3F0) : AppColors.textPrimary;
    final muted = dark ? const Color(0xFFB5C9C2) : AppColors.textSecondary;
    final border = dark ? const Color(0xFF3E554C) : AppColors.border;
    final canvas = dark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final font = GoogleFonts.tajawal().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: font,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: dark ? const Color(0xFF355A51) : AppColors.primaryContainer,
        onPrimaryContainer: dark ? Colors.white : AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: dark ? const Color(0xFF34474E) : const Color(0xFFEAF1F5),
        onSecondaryContainer: foreground,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
        surfaceContainerHighest: dark ? const Color(0xFF2D433B) : const Color(0xFFF1F5F2),
        onSurfaceVariant: muted,
        outline: border,
        outlineVariant: border,
      ),
      scaffoldBackgroundColor: canvas,
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: GoogleFonts.tajawal(
          color: foreground, fontSize: 21, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      textTheme: GoogleFonts.tajawalTextTheme(
        dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: foreground, displayColor: foreground),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? Colors.white : AppColors.primaryDark,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF2B4239) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.tajawal(color: muted),
        labelStyle: GoogleFonts.tajawal(color: muted),
        prefixIconColor: muted,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface,
        elevation: 2,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: muted,
        selectedLabelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: GoogleFonts.tajawal(color: AppColors.primary, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: GoogleFonts.tajawal(color: muted),
        indicatorColor: dark ? const Color(0xFF34564B) : AppColors.primaryContainer,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: muted,
        indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.tajawal(),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: dark ? const Color(0xFF355A51) : AppColors.primaryContainer,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.tajawal(color: foreground, fontSize: 13),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
        subtitleTextStyle: GoogleFonts.tajawal(fontSize: 13, color: muted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700, color: foreground),
        contentTextStyle: GoogleFonts.tajawal(fontSize: 14, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : muted),
      ),
    );
  }
}
