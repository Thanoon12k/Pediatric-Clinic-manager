import '../../data/datasources/examination_datasource.dart';
import '../../data/models/examination_model.dart';
import '../../domain/repositories/examination_repository.dart';

class ExaminationRepositoryImpl implements ExaminationRepository {
  final ExaminationDataSource _ds;
  ExaminationRepositoryImpl(this._ds);

  @override
  Future<List<ExaminationModel>> getExaminations(String patientId) => _ds.getExaminations(patientId);
  @override
  Future<ExaminationModel> addExamination(ExaminationModel e) => _ds.addExamination(e);
  @override
  Future<ExaminationModel> updateExamination(ExaminationModel e) => _ds.updateExamination(e);
  @override
  Future<void> deleteExamination(String id) => _ds.deleteExamination(id);
  @override
  Future<List<GrowthRecordModel>> getGrowthRecords(String patientId) => _ds.getGrowthRecords(patientId);
  @override
  Future<GrowthRecordModel> addGrowthRecord(GrowthRecordModel r) => _ds.addGrowthRecord(r);
}
