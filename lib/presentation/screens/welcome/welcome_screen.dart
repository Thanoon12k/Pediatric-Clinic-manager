import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                // Logo
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.local_hospital_rounded, size: 70, color: Colors.white),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 32),
                Text(AppConstants.appName, style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary))
                    .animate(delay: 200.ms).fadeIn().slideY(begin: 0.4),
                const SizedBox(height: 10),
                Text(
                  'نظام إدارة عيادة الأطفال المتكامل\nرعاية أفضل · متابعة أدق · تواصل أسهل',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.6),
                ).animate(delay: 350.ms).fadeIn(),

                const Spacer(),

                // Features row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Feature(icon: Icons.people_rounded,   label: 'إدارة\nالمرضى'),
                    _Feature(icon: Icons.vaccines_rounded,  label: 'جدول\nالتحصينات'),
                    _Feature(icon: Icons.bar_chart_rounded, label: 'منحنيات\nالنمو'),
                    _Feature(icon: Icons.chat_rounded,      label: 'تواصل\nالأسرة'),
                  ],
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 48),

                // CTA Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeLogin),
                    child: const Text('تسجيل الدخول'),
                  ),
                ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppConstants.routeRegister),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon; final String label;
  const _Feature({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    CircleAvatar(radius: 26, backgroundColor: AppColors.primaryContainer,
        child: Icon(icon, color: AppColors.primary, size: 26)),
    const SizedBox(height: 8),
    Text(label, textAlign: TextAlign.center, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
  ]);
}
