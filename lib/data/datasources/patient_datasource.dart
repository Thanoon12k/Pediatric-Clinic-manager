import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/patient_model.dart';
import '../../core/constants/app_constants.dart';

abstract class PatientDataSource {
  Future<List<PatientModel>> getPatients({required String doctorId, String? search});
  Future<PatientModel> getPatientById(String id);
  Future<PatientModel> createPatient(PatientModel patient);
  Future<PatientModel> updatePatient(PatientModel patient);
  Future<void> deletePatient(String id);
  Future<List<PatientModel>> getPatientsByStatus({required String doctorId, required TreatmentStatus status});
}

class PatientDataSourceImpl implements PatientDataSource {
  final SupabaseClient _client;
  PatientDataSourceImpl(this._client);

  @override
  Future<List<PatientModel>> getPatients({required String doctorId, String? search}) async {
    // Fetch all for this doctor, filter in Dart (avoids ilike type issue on chained builder)
    final data = await _client
        .from(AppConstants.tablePatients)
        .select()
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);
    final all = data.map((e) => PatientModel.fromJson(e)).toList();
    if (search == null || search.isEmpty) return all;
    final q = search.toLowerCase();
    return all.where((p) => p.fullName.toLowerCase().contains(q) || p.guardianPhone.contains(q)).toList();
  }

  @override
  Future<PatientModel> getPatientById(String id) async {
    final data = await _client
        .from(AppConstants.tablePatients)
        .select()
        .eq('id', id)
        .single();
    return PatientModel.fromJson(data);
  }

  @override
  Future<PatientModel> createPatient(PatientModel patient) async {
    final json = patient.toJson()..remove('id')..remove('updated_at');
    final data = await _client
        .from(AppConstants.tablePatients)
        .insert(json)
        .select()
        .single();
    return PatientModel.fromJson(data);
  }

  @override
  Future<PatientModel> updatePatient(PatientModel patient) async {
    final json = patient.toJson()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();
    final data = await _client
        .from(AppConstants.tablePatients)
        .update(json)
        .eq('id', patient.id)
        .select()
        .single();
    return PatientModel.fromJson(data);
  }

  @override
  Future<void> deletePatient(String id) async {
    await _client.from(AppConstants.tablePatients).delete().eq('id', id);
  }

  @override
  Future<List<PatientModel>> getPatientsByStatus({required String doctorId, required TreatmentStatus status}) async {
    final statusStr = status == TreatmentStatus.recovered ? 'recovered' : 'under_treatment';
    final data = await _client
        .from(AppConstants.tablePatients)
        .select()
        .eq('doctor_id', doctorId)
        .eq('treatment_status', statusStr)
        .order('full_name');
    return data.map((e) => PatientModel.fromJson(e)).toList();
  }
}
