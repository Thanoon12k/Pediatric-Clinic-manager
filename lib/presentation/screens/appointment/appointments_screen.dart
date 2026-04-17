import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/appointment_model.dart';
import '../../blocs/appointment/appointment_bloc.dart';
import '../../blocs/doctor/doctor_bloc.dart';
import '../../widgets/app_snackbar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  void _loadDoctor() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) context.read<DoctorBloc>().add(LoadDoctorByUserId(userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoctorBloc, DoctorState>(
      listener: (context, state) {
        if (state is DoctorProfileLoaded && state.doctor != null) {
          setState(() => _doctorId = state.doctor!.id);
          context.read<AppointmentBloc>().add(LoadAppointments(doctorId: state.doctor!.id, date: _selectedDay));
        }
      },
      child: Scaffold(
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
                    context.read<AppointmentBloc>().add(LoadAppointments(doctorId: _doctorId!, date: selected));
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
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
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
                          onConfirm: () => context.read<AppointmentBloc>().add(
                              UpdateAppointmentStatus(id: appt.id, status: AppointmentStatus.confirmed)),
                          onCancel: () => context.read<AppointmentBloc>().add(
                              UpdateAppointmentStatus(id: appt.id, status: AppointmentStatus.cancelled)),
                          onComplete: () => context.read<AppointmentBloc>().add(
                              UpdateAppointmentStatus(id: appt.id, status: AppointmentStatus.completed)),
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
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});
  @override State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _doctorId;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  void _loadDoctor() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) context.read<DoctorBloc>().add(LoadDoctorByUserId(userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoctorBloc, DoctorState>(
      listener: (context, state) {
        if (state is DoctorProfileLoaded && state.doctor != null) {
          setState(() => _doctorId = state.doctor!.id);
          context.read<AppointmentBloc>().add(LoadAvailableSlots(doctorId: state.doctor!.id, date: _selectedDate));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('حجز موعد')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('اختر يوم الموعد', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
                onDaySelected: (selected, focused) {
                  setState(() { _selectedDate = selected; _selectedTime = null; });
                  if (_doctorId != null) {
                    context.read<AppointmentBloc>().add(LoadAvailableSlots(doctorId: _doctorId!, date: selected));
                  }
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                ),
                headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: AppTextStyles.titleMedium),
                locale: 'ar',
              ),
            ),
            const SizedBox(height: 24),
            Text('اختر الوقت المتاح', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                if (state is AppointmentLoading) return const Center(child: CircularProgressIndicator());
                if (state is SlotsLoaded && state.slots.isEmpty) {
                  return const Center(child: Text('لا توجد أوقات متاحة في هذا اليوم'));
                }
                if (state is SlotsLoaded) {
                  return Wrap(
                    spacing: 8, runSpacing: 8,
                    children: state.slots.map((slot) => ChoiceChip(
                      label: Text(slot),
                      selected: _selectedTime == slot,
                      onSelected: (_) => setState(() => _selectedTime = slot),
                      selectedColor: AppColors.primaryContainer,
                    )).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
            Text('سبب الزيارة (اختياري)', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'اذكر سبب الزيارة...', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 24),
            BlocConsumer<AppointmentBloc, AppointmentState>(
              listener: (context, state) {
                if (state is AppointmentSuccess) {
                  AppSnackbar.success(context, state.message);
                  context.pop();
                } else if (state is AppointmentError) {
                  AppSnackbar.error(context, state.message);
                }
              },
              builder: (context, state) => ElevatedButton(
                onPressed: (state is AppointmentLoading || _selectedTime == null) ? null : () {
                  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  context.read<AppointmentBloc>().add(BookAppointment(AppointmentModel(
                    id: const Uuid().v4(),
                    patientId: userId,
                    doctorId: _doctorId!,
                    patientName: Supabase.instance.client.auth.currentUser?.email ?? '',
                    appointmentDate: _selectedDate,
                    appointmentTime: _selectedTime!,
                    reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  )));
                },
                child: state is AppointmentLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_selectedTime == null ? 'اختر وقتاً أولاً' : 'تأكيد الحجز ($_selectedTime)'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
