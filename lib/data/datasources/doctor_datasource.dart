import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/doctor_model.dart';
import '../../core/constants/app_constants.dart';

abstract class DoctorDataSource {
  Future<List<DoctorModel>> getAllDoctors();
  Future<DoctorModel?> getDoctorByUserId(String userId);
  Future<DoctorModel> getDoctorById(String id);
  Future<DoctorModel> createDoctor(DoctorModel doctor);
  Future<DoctorModel> updateDoctor(DoctorModel doctor);
  Future<void> deleteDoctor(String id);
  Future<void> toggleDoctorStatus(String id, bool isActive);
}

class DoctorDataSourceImpl implements DoctorDataSource {
  final SupabaseClient _client;
  DoctorDataSourceImpl(this._client);

  @override
  Future<List<DoctorModel>> getAllDoctors() async {
    final data = await _client.from(AppConstants.tableDoctors).select().order('full_name');
    return data.map((e) => DoctorModel.fromJson(e)).toList();
  }

  @override
  Future<DoctorModel?> getDoctorByUserId(String userId) async {
    final data = await _client
        .from(AppConstants.tableDoctors)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? DoctorModel.fromJson(data) : null;
  }

  @override
  Future<DoctorModel> getDoctorById(String id) async {
    final data = await _client.from(AppConstants.tableDoctors).select().eq('id', id).single();
    return DoctorModel.fromJson(data);
  }

  @override
  Future<DoctorModel> createDoctor(DoctorModel doctor) async {
    final json = doctor.toJson()..remove('id');
    final data = await _client.from(AppConstants.tableDoctors).insert(json).select().single();
    return DoctorModel.fromJson(data);
  }

  @override
  Future<DoctorModel> updateDoctor(DoctorModel doctor) async {
    final data = await _client
        .from(AppConstants.tableDoctors)
        .update(doctor.toJson())
        .eq('id', doctor.id)
        .select()
        .single();
    return DoctorModel.fromJson(data);
  }

  @override
  Future<void> deleteDoctor(String id) async =>
      await _client.from(AppConstants.tableDoctors).delete().eq('id', id);

  @override
  Future<void> toggleDoctorStatus(String id, bool isActive) async =>
      await _client.from(AppConstants.tableDoctors).update({'is_active': isActive}).eq('id', id);
}
