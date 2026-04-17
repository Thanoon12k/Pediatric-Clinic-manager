import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../blocs/auth/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          switch (state.user.role) {
            case UserRole.admin:   context.go(AppConstants.routeAdminDashboard); break;
            case UserRole.doctor:  context.go(AppConstants.routeDoctorDashboard); break;
            case UserRole.patient: context.go(AppConstants.routePatientDashboard); break;
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          context.go(AppConstants.routeWelcome);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, size: 60, color: Colors.white),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(AppConstants.appName, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white))
                    .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text('نظام إدارة عيادة الأطفال', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70))
                    .animate(delay: 450.ms).fadeIn(),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    .animate(delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
