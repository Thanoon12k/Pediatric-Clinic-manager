import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated) context.go(AppConstants.routeWelcome);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      CircleAvatar(radius: 30, backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.person_rounded, size: 35, color: Colors.white)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('مرحباً بك 👋', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                        Text(user?.email ?? '', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                      ])),
                      IconButton(onPressed: () => context.go(AppConstants.routeSettings),
                          icon: const Icon(Icons.settings_rounded, color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Text('ماذا تريد أن تفعل؟', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
                children: [
                  _DashCard(icon: Icons.calendar_today_rounded, label: 'حجز موعد', color: AppColors.primary,
                      onTap: () => context.go(AppConstants.routeAppointmentBook)),
                  _DashCard(icon: Icons.event_note_rounded, label: 'مواعيدي', color: AppColors.secondary,
                      onTap: () => context.go(AppConstants.routeAppointments)),
                  _DashCard(icon: Icons.chat_rounded, label: 'مراسلة الطبيب', color: AppColors.accent,
                      onTap: () => context.go(AppConstants.routeMessages)),
                  _DashCard(icon: Icons.security_rounded, label: 'نصائح سلامة الأطفال', color: AppColors.warning,
                      onTap: () => context.go(AppConstants.routeSafetyTips)),
                  _DashCard(icon: Icons.info_rounded, label: 'ملفي الطبي', color: AppColors.primaryDark,
                      onTap: () {}),
                  _DashCard(icon: Icons.settings_rounded, label: 'الإعدادات', color: AppColors.textSecondary,
                      onTap: () => context.go(AppConstants.routeSettings)),
                ],
              ),
            ])),
          ),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _DashCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 10),
        Text(label, style: AppTextStyles.labelLarge.copyWith(color: color), textAlign: TextAlign.center),
      ]),
    ),
  );
}
