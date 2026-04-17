import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/doctor/doctor_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';
import '../../../data/models/doctor_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorBloc>().add(LoadDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/welcome');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المشرف'),
          actions: [
            IconButton(
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ],
        ),
        body: BlocConsumer<DoctorBloc, DoctorState>(
          listener: (context, state) {
            if (state is DoctorSuccess) {
              AppSnackbar.success(context, state.message);
              context.read<DoctorBloc>().add(LoadDoctors());
            }
            if (state is DoctorError) AppSnackbar.error(context, state.message);
          },
          builder: (context, state) {
            if (state is DoctorLoading) return const Center(child: CircularProgressIndicator());
            if (state is DoctorsLoaded) {
              final active = state.doctors.where((d) => d.isActive).length;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      child: Row(children: [
                        _StatPill(label: 'إجمالي الأطباء', value: '${state.doctors.length}', icon: Icons.medical_services_rounded),
                        const SizedBox(width: 12),
                        _StatPill(label: 'نشطون', value: '$active', icon: Icons.check_circle_rounded),
                        const SizedBox(width: 12),
                        _StatPill(label: 'غير نشطين', value: '${state.doctors.length - active}', icon: Icons.block_rounded),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _DoctorManagementCard(
                          doctor: state.doctors[i],
                          onToggle: () => context.read<DoctorBloc>().add(
                              ToggleDoctorStatus(id: state.doctors[i].id, isActive: !state.doctors[i].isActive)),
                          onDelete: () => _confirmDelete(context, state.doctors[i]),
                        ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.2),
                        childCount: state.doctors.length,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people_outline_rounded, size: 80, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('لا يوجد أطباء مسجلون', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
            ]));
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DoctorModel doctor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطبيب'),
        content: Text('هل تريد حذف د. ${doctor.fullName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { Navigator.pop(context); context.read<DoctorBloc>().add(DeleteDoctor(doctor.id)); },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value; final IconData icon;
  const _StatPill({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white70), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _DoctorManagementCard extends StatelessWidget {
  final DoctorModel doctor; final VoidCallback onToggle, onDelete;
  const _DoctorManagementCard({required this.doctor, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: doctor.isActive ? AppColors.primaryContainer : Colors.grey.shade100,
            child: Text(doctor.fullName[0], style: AppTextStyles.titleLarge.copyWith(
                color: doctor.isActive ? AppColors.primary : AppColors.textSecondary)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('د. ${doctor.fullName}', style: AppTextStyles.titleSmall),
            if (doctor.specialty != null) Text(doctor.specialty!, style: AppTextStyles.bodySmall),
            if (doctor.phone != null) Text(doctor.phone!, style: AppTextStyles.bodySmall),
          ])),
          Column(children: [
            Switch(value: doctor.isActive, onChanged: (_) => onToggle(), activeThumbColor: AppColors.success),
            Text(doctor.isActive ? 'نشط' : 'متوقف',
                style: AppTextStyles.labelSmall.copyWith(color: doctor.isActive ? AppColors.success : AppColors.error)),
          ]),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: onDelete),
        ]),
      ),
    );
  }
}
