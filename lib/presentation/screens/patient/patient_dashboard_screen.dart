import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth/auth_provider.dart';

/// A concise guardian experience: no dead shortcuts or crowded charts.
class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated) context.go(AppConstants.routeWelcome);
    });

    final links = <_GuardianAction>[
      _GuardianAction('حجز موعد', 'احجز زيارة لطفلك', Icons.edit_calendar_outlined,
          AppConstants.routeAppointmentBook),
      _GuardianAction('مواعيدي', 'تابع الزيارات القادمة', Icons.event_note_outlined,
          AppConstants.routeAppointments),
      _GuardianAction('رسائل الطبيب', 'تواصل مع العيادة', Icons.chat_bubble_outline_rounded,
          AppConstants.routeMessages),
      _GuardianAction('إرشادات صحية', 'نصائح للعناية بالأطفال', Icons.health_and_safety_outlined,
          AppConstants.routeSafetyTips),
      _GuardianAction('الإعدادات', 'اللغة والمظهر والحساب', Icons.tune_rounded,
          AppConstants.routeSettings),
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 750 ? 3 : 2;
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const CircleAvatar(
                        radius: 27,
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.child_care_rounded,
                            size: 29, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('أهلاً بك في عيادتي', style: AppTextStyles.titleLarge),
                          const SizedBox(height: 5),
                          Text(email, style: AppTextStyles.bodySmall,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      )),
                      IconButton(
                        tooltip: 'الإعدادات',
                        onPressed: () => context.push(AppConstants.routeSettings),
                        icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  Text('كيف يمكننا مساعدتك؟', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 6),
                  Text('كل ما يخص مواعيد طفلك وتواصلك مع الطبيب في مكان واحد.',
                    style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: links.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      childAspectRatio: columns == 3 ? 1.85 : 1.18,
                    ),
                    itemBuilder: (context, index) => _GuardianTile(
                      action: links[index],
                      onTap: () => context.push(links[index].route),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('تسجيل الخروج'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuardianAction {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  const _GuardianAction(this.title, this.description, this.icon, this.route);
}

class _GuardianTile extends StatelessWidget {
  final _GuardianAction action;
  final VoidCallback onTap;
  const _GuardianTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(action.icon, color: AppColors.primaryDark)),
            const SizedBox(height: 10),
            Text(action.title, style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(action.description, style: AppTextStyles.bodySmall,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ),
  );
}
