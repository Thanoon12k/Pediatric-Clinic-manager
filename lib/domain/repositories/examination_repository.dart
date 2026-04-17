import '../../data/models/examination_model.dart';

abstract class ExaminationRepository {
  Future<List<ExaminationModel>> getExaminations(String patientId);
  Future<ExaminationModel> addExamination(ExaminationModel examination);
  Future<ExaminationModel> updateExamination(ExaminationModel examination);
  Future<void> deleteExamination(String id);
  Future<List<GrowthRecordModel>> getGrowthRecords(String patientId);
  Future<GrowthRecordModel> addGrowthRecord(GrowthRecordModel record);
}
