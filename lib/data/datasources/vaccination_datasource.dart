import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/vaccination_model.dart';
import '../../core/constants/app_constants.dart';

abstract class VaccinationDataSource {
  Future<List<VaccinationModel>> getVaccinations(String patientId);
  Future<VaccinationModel> addVaccination(VaccinationModel v);
  Future<VaccinationModel> updateVaccination(VaccinationModel v);
  Future<void> deleteVaccination(String id);
}

class VaccinationDataSourceImpl implements VaccinationDataSource {
  final SupabaseClient _client;
  VaccinationDataSourceImpl(this._client);

  @override
  Future<List<VaccinationModel>> getVaccinations(String patientId) async {
    final data = await _client
        .from(AppConstants.tableVaccinations)
        .select()
        .eq('patient_id', patientId)
        .order('date_given', ascending: false);
    return data.map((e) => VaccinationModel.fromJson(e)).toList();
  }

  @override
  Future<VaccinationModel> addVaccination(VaccinationModel v) async {
    final json = v.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableVaccinations)
        .insert(json).select().single();
    return VaccinationModel.fromJson(data);
  }

  @override
  Future<VaccinationModel> updateVaccination(VaccinationModel v) async {
    final data = await _client
        .from(AppConstants.tableVaccinations)
        .update(v.toJson()).eq('id', v.id).select().single();
    return VaccinationModel.fromJson(data);
  }

  @override
  Future<void> deleteVaccination(String id) async =>
      await _client.from(AppConstants.tableVaccinations).delete().eq('id', id);
}
