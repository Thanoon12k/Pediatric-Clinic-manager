import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/appointment_model.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/doctor/doctor_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});
  @override ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadDoctor();
    });
  }

  void _loadDoctor() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) ref.read(doctorProvider.notifier).loadDoctorByUserId(userId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DoctorState>(doctorProvider, (previous, next) {
      if (next is DoctorProfileLoaded && next.doctor != null) {
        setState(() => _doctorId = next.doctor!.id);
        ref.read(appointmentProvider.notifier).loadAppointments(doctorId: next.doctor!.id, date: _selectedDay);
      }
    });

    final state = ref.watch(appointmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المواعيد')),
      body: Column(
        children: [
          // Calendar
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() { _selectedDay = selected; _focusedDay = focused; });
                if (_doctorId != null) {
                  ref.read(appointmentProvider.notifier).loadAppointments(doctorId: _doctorId!, date: selected);
                }
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              ),
              headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true,
                  titleTextStyle: AppTextStyles.titleMedium),
              locale: 'ar',
            ),
          ),
          const Divider(height: 1),

          // Appointments list
          Expanded(
            child: Builder(
              builder: (context) {
                if (state is AppointmentLoading) return const Center(child: CircularProgressIndicator());
                if (state is AppointmentsLoaded && state.appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available_rounded, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('لا توجد مواعيد في هذا اليوم', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                if (state is AppointmentsLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.appointments.length,
                    itemBuilder: (context, i) {
                      final appt = state.appointments[i];
                      return _AppointmentCard(
                        appointment: appt,
                        onConfirm: () => ref.read(appointmentProvider.notifier).updateAppointmentStatus(
                            id: appt.id, status: AppointmentStatus.confirmed),
                        onCancel: () => ref.read(appointmentProvider.notifier).updateAppointmentStatus(
                            id: appt.id, status: AppointmentStatus.cancelled),
                        onComplete: () => ref.read(appointmentProvider.notifier).updateAppointmentStatus(
                            id: appt.id, status: AppointmentStatus.completed),
                      ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.2);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onConfirm, onCancel, onComplete;
  const _AppointmentCard({required this.appointment, required this.onConfirm, required this.onCancel, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(appointment.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.person_rounded, color: color)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.patientName, style: AppTextStyles.titleSmall),
                      Text(appointment.appointmentTime, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel(appointment.status), style: AppTextStyles.labelSmall.copyWith(color: color)),
                ),
              ],
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 8),
              Text('السبب: ${appointment.reason}', style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (appointment.status == AppointmentStatus.pending) ...[
                  Expanded(child: OutlinedButton(
                    onPressed: onConfirm,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                    child: const Text('تأكيد'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    child: const Text('إلغاء'),
                  )),
                ],
                if (appointment.status == AppointmentStatus.confirmed) ...[
                  Expanded(child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('تم'),
                  )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed: return AppColors.success;
      case AppointmentStatus.cancelled: return AppColors.error;
      case AppointmentStatus.completed: return AppColors.primary;
      default: return AppColors.warning;
    }
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed: return 'مؤكد';
      case AppointmentStatus.cancelled: return 'ملغي';
      case AppointmentStatus.completed: return 'مكتمل';
      default: return 'معلق';
    }
  }
}

// ─── Book Appointment Screen ─────────────────────────────────────────────────
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});
  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _patientId;
  String? _doctorId;
  String _doctorName = '';
  String? _loadError;
  bool _loadingChildren = true;
  final _reasonCtrl = TextEditingController();
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLinkedChildren);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedChildren() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('تحتاج إلى تسجيل الدخول أولاً');
      // patient_id refers to public.patients.id, never auth.users.id.
      final records = await client
          .from('patients')
          .select('id,doctor_id,full_name')
          .eq('user_id', userId)
          .order('full_name');
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(records);
      setState(() {
        _children = list;
        _loadingChildren = false;
        _loadError = null;
      });
      if (list.isNotEmpty) await _chooseChild(list.first['id'] as String);
    } catch (_) {
      if (mounted) setState(() {
        _loadingChildren = false;
        _loadError = 'تعذر تحميل ملفات الأطفال. تحقق من الاتصال وحاول مجدداً.';
      });
    }
  }

  Future<void> _chooseChild(String id) async {
    final child = _children.firstWhere((c) => c['id'] == id);
    final doctorId = child['doctor_id'] as String;
    setState(() {
      _patientId = id;
      _doctorId = doctorId;
      _selectedTime = null;
      _doctorName = '';
    });
    try {
      final doctor = await Supabase.instance.client
          .from('doctors').select('full_name').eq('id', doctorId).single();
      if (mounted && _patientId == id) {
        setState(() => _doctorName = doctor['full_name'] as String? ?? '');
      }
    } catch (_) {
      // Name is optional: availability service still identifies the doctor.
    }
    if (mounted && _patientId == id) {
      ref.read(appointmentProvider.notifier).loadAvailableSlots(
        doctorId: doctorId, date: _selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentProvider);
    ref.listen<AppointmentState>(appointmentProvider, (previous, next) {
      if (next is AppointmentSuccess) {
        AppSnackbar.success(context, next.message);
        if (context.canPop()) context.pop();
      } else if (next is AppointmentError) {
        AppSnackbar.error(context, next.message);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('حجز موعد لطفلك')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: _loadingChildren
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center),
                TextButton(onPressed: () {
                  setState(() => _loadingChildren = true);
                  _loadLinkedChildren();
                }, child: const Text('إعادة المحاولة')),
              ]))
            : _children.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.family_restroom_outlined, size: 50, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('لم يتم ربط ملف طفل بهذا الحساب',
                      style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('اطلب من العيادة ربط ملف طفلك بحسابك لحجز المواعيد.',
                      style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                  ]),
                ))
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text('ملف الطفل', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _patientId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.child_care_rounded)),
                      items: _children.map((child) => DropdownMenuItem<String>(
                        value: child['id'] as String,
                        child: Text(child['full_name'] as String? ?? 'طفل'),
                      )).toList(),
                      onChanged: (id) {
                        if (id != null) _chooseChild(id);
                      },
                    ),
                    if (_doctorName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('الطبيب: د. $_doctorName', style: AppTextStyles.bodySmall),
                    ],
                    const SizedBox(height: 24),
                    Text('يوم المراجعة', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    Card(
                      child: TableCalendar(
                        firstDay: DateTime.now().subtract(const Duration(days: 1)),
                        lastDay: DateTime.now().add(const Duration(days: 90)),
                        focusedDay: _selectedDate,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDate = selected;
                            _selectedTime = null;
                          });
                          if (_doctorId != null) {
                            ref.read(appointmentProvider.notifier).loadAvailableSlots(
                              doctorId: _doctorId!, date: selected);
                          }
                        },
                        calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: AppTextStyles.titleMedium,
                        ),
                        locale: 'ar',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('الأوقات المتاحة', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    if (state is AppointmentLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
                    else if (state is AppointmentError)
                      Text('تعذر تحميل الأوقات المتاحة. أعد اختيار التاريخ.',
                        style: AppTextStyles.bodySmall)
                    else if (state is SlotsLoaded && state.slots.isEmpty)
                      const Text('لا توجد أوقات متاحة في هذا اليوم.')
                    else if (state is SlotsLoaded)
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: state.slots.map((slot) => ChoiceChip(
                          label: Text(slot),
                          selected: _selectedTime == slot,
                          onSelected: (_) => setState(() => _selectedTime = slot),
                        )).toList(),
                      ),
                    const SizedBox(height: 24),
                    Text('سبب الزيارة (اختياري)', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _reasonCtrl, maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سبب المراجعة...',
                        prefixIcon: Icon(Icons.notes_rounded)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: state is AppointmentLoading || _selectedTime == null ||
                          _doctorId == null || _patientId == null
                        ? null
                        : () {
                            final child = _children.firstWhere((c) => c['id'] == _patientId);
                            ref.read(appointmentProvider.notifier).bookAppointment(
                              AppointmentModel(
                                id: const Uuid().v4(),
                                patientId: _patientId!,
                                doctorId: _doctorId!,
                                patientName: child['full_name'] as String? ?? '',
                                appointmentDate: _selectedDate,
                                appointmentTime: _selectedTime!,
                                reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
                                createdAt: DateTime.now(),
                              ),
                            );
                          },
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(_selectedTime == null
                        ? 'اختر الوقت المناسب أولاً' : 'تأكيد الحجز: $_selectedTime'),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
      )),
    );
  }
}
