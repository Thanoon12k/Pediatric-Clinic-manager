import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/patient_model.dart';
import '../../blocs/patient/patient_bloc.dart';
import '../../widgets/app_snackbar.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  const PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<PatientBloc>().add(LoadPatientById(widget.patientId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientOperationSuccess) {
          AppSnackbar.success(context, state.message);
          context.read<PatientBloc>().add(LoadPatientById(widget.patientId));
        } else if (state is PatientError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is PatientLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state is PatientLoaded) {
          return _buildContent(state.patient);
        }
        return const Scaffold(body: Center(child: Text('تعذر تحميل بيانات المريض')));
      },
    );
  }

  Widget _buildContent(PatientModel patient) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: patient.avatarUrl != null
                            ? ClipOval(child: Image.network(patient.avatarUrl!, width: 90, height: 90, fit: BoxFit.cover))
                            : Text(patient.fullName[0], style: AppTextStyles.headlineLarge.copyWith(color: Colors.white)),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 12),

                      Text(patient.fullName, style: AppTextStyles.titleLarge.copyWith(color: Colors.white))
                          .animate(delay: 200.ms).fadeIn(),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoChip(label: patient.ageDisplay),
                          const SizedBox(width: 8),
                          _InfoChip(label: patient.gender == Gender.male ? 'ذكر' : 'أنثى'),
                          if (patient.bloodType != null) ...[
                            const SizedBox(width: 8),
                            _InfoChip(label: patient.bloodType!),
                          ],
                        ],
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.go('/doctor/patients/${patient.id}/edit'),
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (v) {
                  if (v == 'pdf') context.go('/pdf-report/${patient.id}');
                  if (v == 'delete') _confirmDelete(context, patient);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded), SizedBox(width: 8), Text('تقرير PDF')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.red), SizedBox(width: 8), Text('حذف المريض', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'المعلومات'),
                Tab(text: 'الفحوصات'),
                Tab(text: 'التحصينات'),
                Tab(text: 'الأدوية'),
                Tab(text: 'الوسائط'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(patient: patient),
            _ActionTab(label: 'الفحوصات', onTap: () => context.go('/examinations/${patient.id}')),
            _ActionTab(label: 'التحصينات', onTap: () => context.go('/vaccinations/${patient.id}')),
            _ActionTab(label: 'الأدوية', onTap: () => context.go(AppConstants.routeMedications)),
            _ActionTab(label: 'الوسائط والصور', onTap: () => context.go('/charts/${patient.id}')),
          ],
        ),
      ),

      // FAB — Message doctor
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/messages'),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('التواصل'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${patient.fullName}؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<PatientBloc>().add(DeletePatient(patient.id));
              context.go(AppConstants.routePatientList);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final PatientModel patient;
  const _InfoTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(title: 'البيانات الشخصية', children: [
          _InfoRow(icon: Icons.cake_rounded, label: 'تاريخ الميلاد', value: _fmt(patient.dateOfBirth)),
          _InfoRow(icon: Icons.monitor_weight_rounded, label: 'الوزن', value: patient.weight != null ? '${patient.weight} كغ' : '—'),
          _InfoRow(icon: Icons.height_rounded, label: 'الطول', value: patient.height != null ? '${patient.height} سم' : '—'),
          _InfoRow(icon: Icons.bloodtype_rounded, label: 'فصيلة الدم', value: patient.bloodType ?? '—'),
        ]),
        const SizedBox(height: 16),
        _SectionCard(title: 'ولي الأمر', children: [
          _InfoRow(icon: Icons.person_rounded, label: 'الاسم', value: patient.guardianName),
          _InfoRow(icon: Icons.phone_rounded, label: 'الهاتف', value: patient.guardianPhone),
          if (patient.address != null) _InfoRow(icon: Icons.location_on_rounded, label: 'العنوان', value: patient.address!),
        ]),
        const SizedBox(height: 16),
        _SectionCard(title: 'الحالة الصحية', children: [
          _InfoRow(
            icon: patient.treatmentStatus == TreatmentStatus.recovered ? Icons.favorite_rounded : Icons.medical_services_rounded,
            label: 'حالة العلاج',
            value: patient.treatmentStatus == TreatmentStatus.recovered ? 'تم الشفاء ✓' : 'قيد العلاج',
            valueColor: patient.treatmentStatus == TreatmentStatus.recovered ? AppColors.success : AppColors.primary,
          ),
          if (patient.allergies != null) _InfoRow(icon: Icons.warning_amber_rounded, label: 'الحساسية', value: patient.allergies!),
          if (patient.chronicDiseases != null) _InfoRow(icon: Icons.local_hospital_rounded, label: 'أمراض مزمنة', value: patient.chronicDiseases!),
          if (patient.nextVisitDate != null) _InfoRow(icon: Icons.event_rounded, label: 'المراجعة القادمة', value: _fmt(patient.nextVisitDate!), valueColor: AppColors.primary),
        ]),
        if (patient.notes != null) ...[
          const SizedBox(height: 16),
          _SectionCard(title: 'ملاحظات', children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(patient.notes!, style: AppTextStyles.bodyMedium),
            ),
          ]),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionTab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionTab({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text('فتح $label'),
      ),
    );
  }
}
