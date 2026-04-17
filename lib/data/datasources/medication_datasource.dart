import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/medication_model.dart';
import '../../core/constants/app_constants.dart';

abstract class MedicationDataSource {
  Future<List<MedicationModel>> getMedications(String doctorId);
  Future<MedicationModel> addMedication(MedicationModel m);
  Future<MedicationModel> updateMedication(MedicationModel m);
  Future<void> deleteMedication(String id);
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId);
  Future<PrescriptionModel> addPrescription(PrescriptionModel p);
  Future<void> deletePrescription(String id);
}

class MedicationDataSourceImpl implements MedicationDataSource {
  final SupabaseClient _client;
  MedicationDataSourceImpl(this._client);

  @override
  Future<List<MedicationModel>> getMedications(String doctorId) async {
    final data = await _client
        .from(AppConstants.tableMedications)
        .select()
        .eq('doctor_id', doctorId)
        .order('name');
    return data.map((e) => MedicationModel.fromJson(e)).toList();
  }

  @override
  Future<MedicationModel> addMedication(MedicationModel m) async {
    final json = m.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableMedications)
        .insert(json).select().single();
    return MedicationModel.fromJson(data);
  }

  @override
  Future<MedicationModel> updateMedication(MedicationModel m) async {
    final data = await _client
        .from(AppConstants.tableMedications)
        .update(m.toJson()).eq('id', m.id).select().single();
    return MedicationModel.fromJson(data);
  }

  @override
  Future<void> deleteMedication(String id) async =>
      await _client.from(AppConstants.tableMedications).delete().eq('id', id);

  @override
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    final data = await _client
        .from(AppConstants.tablePrescriptions)
        .select()
        .eq('patient_id', patientId)
        .order('prescribed_at', ascending: false);
    return data.map((e) => PrescriptionModel.fromJson(e)).toList();
  }

  @override
  Future<PrescriptionModel> addPrescription(PrescriptionModel p) async {
    final json = p.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tablePrescriptions)
        .insert(json).select().single();
    return PrescriptionModel.fromJson(data);
  }

  @override
  Future<void> deletePrescription(String id) async =>
      await _client.from(AppConstants.tablePrescriptions).delete().eq('id', id);
}
