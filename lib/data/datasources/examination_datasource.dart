import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/examination_model.dart';
import '../../core/constants/app_constants.dart';

abstract class ExaminationDataSource {
  Future<List<ExaminationModel>> getExaminations(String patientId);
  Future<ExaminationModel> addExamination(ExaminationModel e);
  Future<ExaminationModel> updateExamination(ExaminationModel e);
  Future<void> deleteExamination(String id);
  Future<List<GrowthRecordModel>> getGrowthRecords(String patientId);
  Future<GrowthRecordModel> addGrowthRecord(GrowthRecordModel r);
}

class ExaminationDataSourceImpl implements ExaminationDataSource {
  final SupabaseClient _client;
  ExaminationDataSourceImpl(this._client);

  @override
  Future<List<ExaminationModel>> getExaminations(String patientId) async {
    final data = await _client
        .from(AppConstants.tableExaminations)
        .select()
        .eq('patient_id', patientId)
        .order('examination_date', ascending: false);
    return data.map((e) => ExaminationModel.fromJson(e)).toList();
  }

  @override
  Future<ExaminationModel> addExamination(ExaminationModel e) async {
    final json = e.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableExaminations)
        .insert(json).select().single();
    return ExaminationModel.fromJson(data);
  }

  @override
  Future<ExaminationModel> updateExamination(ExaminationModel e) async {
    final data = await _client
        .from(AppConstants.tableExaminations)
        .update(e.toJson()).eq('id', e.id).select().single();
    return ExaminationModel.fromJson(data);
  }

  @override
  Future<void> deleteExamination(String id) async =>
      await _client.from(AppConstants.tableExaminations).delete().eq('id', id);

  @override
  Future<List<GrowthRecordModel>> getGrowthRecords(String patientId) async {
    final data = await _client
        .from(AppConstants.tableGrowthRecords)
        .select()
        .eq('patient_id', patientId)
        .order('record_date');
    return data.map((e) => GrowthRecordModel.fromJson(e)).toList();
  }

  @override
  Future<GrowthRecordModel> addGrowthRecord(GrowthRecordModel r) async {
    final json = r.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableGrowthRecords)
        .insert(json).select().single();
    return GrowthRecordModel.fromJson(data);
  }
}
