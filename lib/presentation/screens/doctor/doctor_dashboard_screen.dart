import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/patient/patient_provider.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/doctor/doctor_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/patient_list_tile.dart';

/// Home-first clinical workflow. The entire page remains usable on a 320px
/// phone and grows into a NavigationRail dashboard on a tablet.
class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  String? _doctorId;
  String _doctorName = '';
  String _search = '';
  AppointmentStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        ref.read(doctorProvider.notifier).loadDoctorByUserId(userId);
      }
    });
  }

  Future<void> _refresh() async {
    final id = _doctorId;
    if (id == null) return;
    await Future.wait([
      ref.read(patientProvider.notifier).loadPatients(doctorId: id),
      ref.read(appointmentProvider.notifier).loadAppointments(
        doctorId: id, date: DateTime.now()),
    ]);
  }

  Future<void> _openPatient(String id) async {
    await context.push('/doctor/patients/$id');
    if (mounted) await _refresh();
  }

  void _selectPage(int index) {
    if (index == 3) {
      _showMore();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showMore() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('جميع الأدوات', style: AppTextStyles.titleLarge),
              const SizedBox(height: 14),
              _moreItem(sheetContext, 'طابور المرضى', Icons.format_list_numbered_rtl_rounded, AppConstants.routeClinicQueue),
              _moreItem(sheetContext, 'المحادثات', Icons.chat_bubble_outline_rounded, AppConstants.routeMessages),
              _moreItem(sheetContext, 'الأدوية', Icons.medication_outlined, AppConstants.routeMedications),
              _moreItem(sheetContext, 'الملف المهني', Icons.badge_outlined, AppConstants.routeDoctorProfile),
              _moreItem(sheetContext, 'إرشادات صحية', Icons.health_and_safety_outlined, AppConstants.routeSafetyTips),
              _moreItem(sheetContext, 'العمليات غير المكتملة', Icons.sync_problem_outlined, AppConstants.routeFailedOps),
              _moreItem(sheetContext, 'الإعدادات', Icons.tune_rounded, AppConstants.routeSettings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreItem(BuildContext sheetContext, String label, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_left_rounded, size: 20),
      onTap: () {
        Navigator.pop(sheetContext);
        context.push(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthBlocState>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated && mounted) context.go(AppConstants.routeWelcome);
    });
    ref.listen<DoctorState>(doctorProvider, (previous, next) {
      if (next is DoctorProfileLoaded && next.doctor != null &&
          next.doctor!.id != _doctorId) {
        final doctor = next.doctor!;
        setState(() {
          _doctorId = doctor.id;
          _doctorName = doctor.fullName;
        });
        _refresh();
      }
    });
    ref.listen<AppointmentState>(appointmentProvider, (previous, next) {
      if (next is AppointmentSuccess && _doctorId != null) {
        ref.read(appointmentProvider.notifier).loadAppointments(
          doctorId: _doctorId!, date: DateTime.now());
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 800;
    return Scaffold(
      body: Row(
        children: [
          if (wide) NavigationRail(
            extended: width >= 1150,
            selectedIndex: _selectedIndex,
            groupAlignment: -0.7,
            labelType: width >= 1150 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            onDestinationSelected: _selectPage,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircleAvatar(
                radius: 25, backgroundColor: AppColors.primaryContainer,
                child: const Icon(Icons.child_care_rounded, color: AppColors.primary, size: 28),
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('الرئيسية')),
              NavigationRailDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: Text('المرضى')),
              NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: Text('المواعيد')),
              NavigationRailDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: Text('المزيد')),
            ],
          ),
          Expanded(child: IndexedStack(
            index: _selectedIndex,
            children: [_homePage(), _patientsPage(), _appointmentsPage()],
          )),
        ],
      ),
      bottomNavigationBar: wide ? null : NavigationBar(
        height: 74,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'المرضى'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'المواعيد'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'المزيد'),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/doctor/patients/add');
                if (mounted) await _refresh();
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('مريض جديد'),
            )
          : null,
    );
  }

  Widget _content(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: child,
    ),
  );

  Widget _homePage() {
    final patients = ref.watch(patientProvider);
    final appointments = ref.watch(appointmentProvider);
    final patientCount = patients is PatientsLoaded ? patients.patients.length : 0;
    final recoveredCount = patients is PatientsLoaded
        ? patients.patients.where((p) => p.treatmentStatus == TreatmentStatus.recovered).length : 0;
    final today = appointments is AppointmentsLoaded ? appointments.appointments : <AppointmentModel>[];
    final pending = today.where((a) => a.status == AppointmentStatus.pending).length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _content(LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 2;
        final actions = constraints.maxWidth >= 760 ? 4 : 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          children: [
            _header(),
            const SizedBox(height: 26),
            Row(children: [
              Expanded(child: Text('نظرة سريعة', style: AppTextStyles.titleLarge)),
              Text('اليوم', style: AppTextStyles.labelMedium),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 3 ? 2.3 : 1.6,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'مواعيد اليوم', value: '${today.length}', icon: Icons.event_note_rounded, color: AppColors.primary),
                StatCard(label: 'بانتظار التأكيد', value: '$pending', icon: Icons.hourglass_empty_rounded, color: AppColors.warning),
                StatCard(label: 'إجمالي المرضى', value: '$patientCount', icon: Icons.groups_2_outlined, color: AppColors.info),
                StatCard(label: 'حالات متعافية', value: '$recoveredCount', icon: Icons.favorite_outline_rounded, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 26),
            Text('اختصارات العيادة', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: actions,
              childAspectRatio: actions == 4 ? 2.1 : 2.15,
              mainAxisSpacing: 10, crossAxisSpacing: 10,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                _action('إضافة مريض', Icons.person_add_alt_outlined, () async {
                  await context.push('/doctor/patients/add');
                  if (mounted) await _refresh();
                }),
                _action('المواعيد', Icons.calendar_month_outlined, () => _selectPage(2)),
                _action('طابور المرضى', Icons.format_list_numbered_rtl_rounded, () => context.push(AppConstants.routeClinicQueue)),
                _action('المرضى', Icons.people_outline_rounded, () => _selectPage(1)),
                _action('المحادثات', Icons.chat_outlined, () => context.push(AppConstants.routeMessages)),
                _action('الأدوية', Icons.medication_outlined, () => context.push(AppConstants.routeMedications)),
                _action('النصائح', Icons.health_and_safety_outlined, () => context.push(AppConstants.routeSafetyTips)),
                _action('ملف الطبيب', Icons.badge_outlined, () => context.push(AppConstants.routeDoctorProfile)),
                _action('الإعدادات', Icons.tune_outlined, () => context.push(AppConstants.routeSettings)),
              ],
            ),
            const SizedBox(height: 26),
            Row(children: [
              Expanded(child: Text('جدول اليوم', style: AppTextStyles.titleLarge)),
              TextButton.icon(
                onPressed: () => _selectPage(2),
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('عرض الكل'),
              ),
            ]),
            const SizedBox(height: 10),
            if (_doctorId == null) _notice('جارٍ تحميل بيانات العيادة...', Icons.hourglass_empty_rounded)
            else if (appointments is AppointmentLoading) const Center(child: Padding(
              padding: EdgeInsets.all(26), child: CircularProgressIndicator()))
            else if (appointments is AppointmentError) _notice('تعذر تحميل المواعيد. اسحب للتحديث.', Icons.wifi_off_outlined)
            else if (today.isEmpty) _notice('لا توجد مواعيد مسجلة لهذا اليوم', Icons.event_available_outlined)
            else ...today.take(5).map(_appointmentTile),
          ],
        );
      })),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.child_care_rounded, size: 30, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('صباح الخير، أهلاً بك', style: AppTextStyles.bodySmall),
            const SizedBox(height: 5),
            Text(_doctorName.isEmpty ? 'عيادتي للأطفال' : 'د. $_doctorName',
              maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleLarge),
            const SizedBox(height: 3),
            Text(MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
              style: AppTextStyles.labelMedium),
          ],
        )),
        IconButton(
          tooltip: 'تحديث البيانات', onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary)),
        IconButton(
          tooltip: 'الإعدادات',
          onPressed: () => context.push(AppConstants.routeSettings),
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: AppColors.primaryContainer,
            child: Icon(icon, size: 21, color: AppColors.primaryDark)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge)),
        ]),
      ),
    ),
  );

  Widget _pageTitle(String title, String subtitle, {Widget? action}) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.headlineSmall),
        const SizedBox(height: 5),
        Text(subtitle, style: AppTextStyles.bodySmall),
      ])),
      if (action != null) action,
    ]),
  );

  Widget _patientsPage() {
    final state = ref.watch(patientProvider);
    final all = state is PatientsLoaded ? state.patients : <PatientModel>[];
    final query = _search.trim().toLowerCase();
    final filtered = query.isEmpty ? all : all.where((patient) =>
        patient.fullName.toLowerCase().contains(query) ||
        patient.guardianPhone.contains(query) ||
        patient.guardianName.toLowerCase().contains(query)).toList();

    return _content(Column(children: [
      _pageTitle('ملفات المرضى', 'جميع ملفات الأطفال والسجل الطبي',
        action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: TextField(
          onChanged: (value) => setState(() => _search = value),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ابحث بالاسم أو اسم ولي الأمر أو الهاتف',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(child: state is PatientLoading
        ? const Center(child: CircularProgressIndicator())
        : state is PatientError
          ? _notice('تعذر جلب ملفات المرضى، اضغط للتحديث', Icons.wifi_off_rounded, onTap: _refresh)
          : filtered.isEmpty
            ? _notice(query.isEmpty ? 'لا توجد ملفات مرضى بعد' : 'لا توجد نتائج مطابقة للبحث',
                Icons.person_search_outlined)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 90),
                itemCount: filtered.length,
                itemBuilder: (context, i) => PatientListTile(
                  patient: filtered[i],
                  onTap: () => _openPatient(filtered[i].id)),
              ),
      ),
    ]));
  }

  Widget _appointmentsPage() {
    final state = ref.watch(appointmentProvider);
    final all = state is AppointmentsLoaded ? state.appointments : <AppointmentModel>[];
    final filtered = _statusFilter == null ? all :
        all.where((a) => a.status == _statusFilter).toList();

    return _content(Column(children: [
      _pageTitle('مواعيد اليوم', 'ترتيب ومتابعة مراجعات الأطفال',
        action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))),
      SizedBox(
        height: 50,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip('الكل', null),
            _filterChip('بانتظار التأكيد', AppointmentStatus.pending),
            _filterChip('مؤكد', AppointmentStatus.confirmed),
            _filterChip('مكتمل', AppointmentStatus.completed),
            _filterChip('ملغي', AppointmentStatus.cancelled),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: state is AppointmentLoading
        ? const Center(child: CircularProgressIndicator())
        : state is AppointmentError
          ? _notice('تعذر جلب المواعيد، اضغط للتحديث', Icons.wifi_off_rounded, onTap: _refresh)
          : filtered.isEmpty
            ? _notice('لا توجد مواعيد ضمن هذه الفئة', Icons.event_available_outlined)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _appointmentTile(filtered[i]),
              )),
    ]));
  }

  Widget _filterChip(String title, AppointmentStatus? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _statusFilter = status),
      ),
    );
  }

  Widget _appointmentTile(AppointmentModel appointment) {
    final color = switch (appointment.status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.info,
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
    };
    final label = switch (appointment.status) {
      AppointmentStatus.pending => 'بانتظار التأكيد',
      AppointmentStatus.confirmed => 'مؤكد',
      AppointmentStatus.completed => 'مكتمل',
      AppointmentStatus.cancelled => 'ملغي',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openPatient(appointment.patientId),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.child_care_outlined, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appointment.patientName.isEmpty ? 'مريض' : appointment.patientName,
                style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(appointment.appointmentTime, style: AppTextStyles.bodySmall),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.11)),
                child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
              ),
              if (appointment.status == AppointmentStatus.pending)
                TextButton(
                  onPressed: () => ref.read(appointmentProvider.notifier)
                      .updateAppointmentStatus(id: appointment.id, status: AppointmentStatus.confirmed),
                  child: const Text('تأكيد الموعد'),
                )
              else if (appointment.status == AppointmentStatus.confirmed)
                TextButton(
                  onPressed: () => ref.read(appointmentProvider.notifier)
                      .updateAppointmentStatus(id: appointment.id, status: AppointmentStatus.completed),
                  child: const Text('إكمال الزيارة'),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _notice(String message, IconData icon, {VoidCallback? onTap}) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 43, color: AppColors.primaryLight),
        const SizedBox(height: 12),
        Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        if (onTap != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(onPressed: onTap, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ],
      ]),
    ),
  );
}
