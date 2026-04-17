import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.success, icon: Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.error, icon: Icons.error_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.primary, icon: Icons.info_rounded);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.warning, icon: Icons.warning_rounded);
  }

  static void _show(BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white))),
        ]),
      ),
    );
  }
}
