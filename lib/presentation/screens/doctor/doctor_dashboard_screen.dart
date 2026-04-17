import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/patient/patient_bloc.dart';
import '../../blocs/appointment/appointment_bloc.dart';
import '../../blocs/doctor/doctor_bloc.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/patient_list_tile.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});
  @override State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  String? _doctorId;
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    context.read<DoctorBloc>().add(LoadDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthBlocState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) context.go(AppConstants.routeWelcome);
          },
        ),
        BlocListener<DoctorBloc, DoctorState>(
          listener: (context, state) {
            if (state is DoctorProfileLoaded && state.doctor != null) {
              setState(() {
                _doctorId = state.doctor!.id;
                _doctorName = state.doctor!.fullName;
              });
              context.read<PatientBloc>().add(LoadPatients(doctorId: state.doctor!.id));
              context.read<AppointmentBloc>().add(LoadAppointments(
                doctorId: state.doctor!.id,
                date: DateTime.now(),
              ));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _buildCurrentPage(),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () => context.go('/doctor/patients/add'),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('إضافة مريض'),
              )
            : null,
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0: return _buildHomePage();
      case 1: return _buildPatientsPage();
      case 2: return _buildAppointmentsPage();
      case 3: return _buildMessagesPage();
      default: return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180, pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        CircleAvatar(radius: 28, backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, color: Colors.white, size: 30)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('مرحباً بك 👋', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                          Text('د. $_doctorName', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                        ])),
                        IconButton(onPressed: () => context.go(AppConstants.routeSettings),
                            icon: const Icon(Icons.settings_rounded, color: Colors.white)),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.go(AppConstants.routeFailedOps),
              icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            BlocBuilder<PatientBloc, PatientState>(
              builder: (context, patientState) {
                final patientCount = patientState is PatientsLoaded ? patientState.patients.length : 0;
                final recovered = patientState is PatientsLoaded
                    ? patientState.patients.where((p) => p.treatmentStatus == TreatmentStatus.recovered).length : 0;
                return BlocBuilder<AppointmentBloc, AppointmentState>(
                  builder: (context, apptState) {
                    final todayCount = apptState is AppointmentsLoaded ? apptState.appointments.length : 0;
                    return Row(children: [
                      Expanded(child: StatCard(label: 'مواعيد اليوم', value: '$todayCount', icon: Icons.calendar_today_rounded, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'إجمالي المرضى', value: '$patientCount', icon: Icons.people_rounded, color: AppColors.secondary)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'تعافوا', value: '$recovered', icon: Icons.favorite_rounded, color: AppColors.accent)),
                    ]);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text('إجراءات سريعة', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              children: [
                _QuickAction(icon: Icons.person_add_rounded, label: 'مريض جديد', color: AppColors.primary,
                    onTap: () => context.go('/doctor/patients/add')),
                _QuickAction(icon: Icons.calendar_today_rounded, label: 'المواعيد', color: AppColors.secondary,
                    onTap: () => setState(() => _selectedIndex = 2)),
                _QuickAction(icon: Icons.vaccines_rounded, label: 'التحصينات', color: AppColors.accent,
                    onTap: () => _doctorId != null ? context.go('/vaccinations/$_doctorId') : null),
                _QuickAction(icon: Icons.medication_rounded, label: 'الأدوية', color: AppColors.warning,
                    onTap: () => context.go(AppConstants.routeMedications)),
                _QuickAction(icon: Icons.healing_rounded, label: 'نصائح صحية', color: AppColors.info,
                    onTap: () => context.go(AppConstants.routeSafetyTips)),
                _QuickAction(icon: Icons.person_rounded, label: 'ملفي', color: AppColors.primaryDark,
                    onTap: () => context.go(AppConstants.routeDoctorProfile)),
              ],
            ),
            const SizedBox(height: 24),
            Text('مواعيد اليوم', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                if (state is AppointmentLoading) return const Center(child: CircularProgressIndicator());
                if (state is AppointmentsLoaded && state.appointments.isEmpty) {
                  return _EmptyState(message: 'لا توجد مواعيد اليوم', icon: Icons.event_available_rounded);
                }
                if (state is AppointmentsLoaded) {
                  return Column(children: state.appointments.take(5).map((appt) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: _apptColor(appt.status).withValues(alpha: 0.1),
                          child: Icon(Icons.access_time_rounded, color: _apptColor(appt.status))),
                      title: Text(appt.patientName, style: AppTextStyles.titleSmall),
                      subtitle: Text(appt.appointmentTime, style: AppTextStyles.bodySmall),
                      trailing: _StatusBadge(status: appt.status.name, color: _apptColor(appt.status)),
                      onTap: () => context.go('/doctor/patients/${appt.patientId}'),
                    ),
                  )).toList());
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 32),
          ])),
        ),
      ],
    );
  }

  Widget _buildPatientsPage() {
    return Column(children: [
      Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 16, right: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('قائمة المرضى', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) {
              if (_doctorId != null) context.read<PatientBloc>().add(LoadPatients(doctorId: _doctorId!, search: v));
            },
            decoration: InputDecoration(
              hintText: 'البحث عن مريض...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ]),
      ),
      Expanded(
        child: BlocBuilder<PatientBloc, PatientState>(
          builder: (context, state) {
            if (state is PatientLoading) return const Center(child: CircularProgressIndicator());
            if (state is PatientsLoaded && state.patients.isEmpty) return _EmptyState(message: 'لا يوجد مرضى', icon: Icons.people_outline_rounded);
            if (state is PatientsLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.patients.length,
                itemBuilder: (context, i) => PatientListTile(
                  patient: state.patients[i],
                  onTap: () => context.go('/doctor/patients/${state.patients[i].id}'),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ]);
  }

  Widget _buildAppointmentsPage() {
    return Column(children: [
      Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 16, right: 16),
        child: Text('المواعيد', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
      ),
      Expanded(
        child: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            if (state is AppointmentLoading) return const Center(child: CircularProgressIndicator());
            if (state is AppointmentsLoaded && state.appointments.isEmpty) return _EmptyState(message: 'لا توجد مواعيد', icon: Icons.event_available_rounded);
            if (state is AppointmentsLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.appointments.length,
                itemBuilder: (context, i) {
                  final appt = state.appointments[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: _apptColor(appt.status).withValues(alpha: 0.1),
                            child: Icon(Icons.access_time_rounded, color: _apptColor(appt.status))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(appt.patientName, style: AppTextStyles.titleSmall),
                          Text(appt.appointmentTime, style: AppTextStyles.bodySmall),
                        ])),
                        _StatusBadge(status: appt.status.name, color: _apptColor(appt.status)),
                      ]),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ]);
  }

  Widget _buildMessagesPage() => Column(children: [
    Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 16, right: 16),
      child: Text('رسائل المرضى', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
    ),
    Expanded(child: Center(child: _EmptyState(message: 'لا توجد محادثات', icon: Icons.chat_bubble_outline_rounded))),
  ]);

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (i) => setState(() => _selectedIndex = i),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
      BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'المرضى'),
      BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'المواعيد'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'الرسائل'),
    ],
  );

  Color _apptColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return AppColors.success;
      case AppointmentStatus.cancelled: return AppColors.error;
      case AppointmentStatus.completed: return AppColors.primary;
      default: return AppColors.warning;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback? onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: color), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status; final Color color;
  const _StatusBadge({required this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    final labels = {'pending': 'معلق', 'confirmed': 'مؤكد', 'cancelled': 'ملغي', 'completed': 'مكتمل'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message; final IconData icon;
  const _EmptyState({required this.message, required this.icon});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: AppColors.textHint),
    const SizedBox(height: 16),
    Text(message, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
  ]));
}
