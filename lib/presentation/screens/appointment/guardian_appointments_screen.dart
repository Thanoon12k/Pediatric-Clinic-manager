import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/appointment_model.dart';

/// The guardian sees bookings for children linked via patients.user_id.
/// It does not attempt to load a doctor profile for a guardian user.
class GuardianAppointmentsScreen extends StatefulWidget {
  const GuardianAppointmentsScreen({super.key});

  @override
  State<GuardianAppointmentsScreen> createState() => _GuardianAppointmentsScreenState();
}

class _GuardianAppointmentsScreenState extends State<GuardianAppointmentsScreen> {
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppointmentModel>> _load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('يرجى تسجيل الدخول مجدداً');
    final children = await client.from('patients')
        .select('id').eq('user_id', uid);
    final ids = children.map((row) => row['id'] as String).toList();
    if (ids.isEmpty) return [];
    final appointments = await client.from('appointments')
        .select().inFilter('patient_id', ids)
        .order('appointment_date', ascending: false);
    return appointments.map((row) => AppointmentModel.fromJson(row)).toList();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مواعيد أطفالي')),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: FutureBuilder<List<AppointmentModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined, size: 42, color: AppColors.primary),
                const SizedBox(height: 12),
                Text('تعذر تحميل المواعيد', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                TextButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
              ],
            ));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.event_available_outlined, size: 54, color: AppColors.primaryLight),
                const SizedBox(height: 16),
                Text('لا توجد مواعيد مسجلة حالياً',
                  style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('يمكنك العودة إلى الرئيسية لحجز موعد لطفلك.',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                final status = switch (a.status) {
                  AppointmentStatus.pending => 'بانتظار التأكيد',
                  AppointmentStatus.confirmed => 'مؤكد',
                  AppointmentStatus.completed => 'مكتمل',
                  AppointmentStatus.cancelled => 'ملغي',
                };
                final color = switch (a.status) {
                  AppointmentStatus.pending => AppColors.warning,
                  AppointmentStatus.confirmed => AppColors.info,
                  AppointmentStatus.completed => AppColors.success,
                  AppointmentStatus.cancelled => AppColors.error,
                };
                return Card(
                  margin: const EdgeInsets.only(bottom: 11),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.child_care_outlined, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.patientName.isEmpty ? 'مراجعة طفل' : a.patientName,
                          style: AppTextStyles.titleSmall),
                        const SizedBox(height: 5),
                        Text('${a.appointmentDate.day}/${a.appointmentDate.month}/${a.appointmentDate.year}  •  ${a.appointmentTime}',
                          style: AppTextStyles.bodySmall),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: color)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    )),
  );
}
