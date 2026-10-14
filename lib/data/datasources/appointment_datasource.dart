import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/doctor_model.dart';
import '../../core/constants/app_constants.dart';

abstract class AppointmentDataSource {
  Future<List<AppointmentModel>> getAppointments({required String doctorId, DateTime? date});
  Future<List<AppointmentModel>> getPatientAppointments(String patientId);
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<AppointmentModel> updateAppointmentStatus({required String id, required AppointmentStatus status, String? notes});
  Future<void> cancelAppointment(String id);
  Future<List<String>> getAvailableTimeSlots({required String doctorId, required DateTime date});
}

class AppointmentDataSourceImpl implements AppointmentDataSource {
  final SupabaseClient _client;
  AppointmentDataSourceImpl(this._client);

  @override
  Future<List<AppointmentModel>> getAppointments({required String doctorId, DateTime? date}) async {
    var query = _client
        .from(AppConstants.tableAppointments)
        .select()
        .eq('doctor_id', doctorId);
    if (date != null) {
      final dateStr = date.toIso8601String().split('T').first;
      query = query.eq('appointment_date', dateStr);
    }
    final data = await query.order('appointment_date').order('appointment_time');
    return data.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  @override
  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    final data = await _client
        .from(AppConstants.tableAppointments)
        .select()
        .eq('patient_id', patientId)
        .order('appointment_date', ascending: false);
    return data.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final json = appointment.toJson()..remove('id')..remove('updated_at');
    final data = await _client
        .from(AppConstants.tableAppointments)
        .insert(json)
        .select()
        .single();
    return AppointmentModel.fromJson(data);
  }

  @override
  Future<AppointmentModel> updateAppointmentStatus({
    required String id,
    required AppointmentStatus status,
    String? notes,
  }) async {
    final data = await _client
        .from(AppConstants.tableAppointments)
        .update({
          'status': status.name,
          if (notes != null) 'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return AppointmentModel.fromJson(data);
  }

  @override
  Future<void> cancelAppointment(String id) async {
    await _client
        .from(AppConstants.tableAppointments)
        .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<String>> getAvailableTimeSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final day = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // Server-authoritative: never expose other patients' appointment rows.
    final result = await _client.rpc('available_appointment_slots', params: {
      'p_doctor_id': doctorId,
      'p_date': day,
    });
    return (result as List<dynamic>).map((row) =>
      (row as Map<String, dynamic>)['slot'] as String).toList();
  }
}
