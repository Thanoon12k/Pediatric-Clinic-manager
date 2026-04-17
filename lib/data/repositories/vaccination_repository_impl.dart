import '../../data/datasources/vaccination_datasource.dart';
import '../../data/models/vaccination_model.dart';
import '../../domain/repositories/vaccination_repository.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  final VaccinationDataSource _ds;
  VaccinationRepositoryImpl(this._ds);

  @override
  Future<List<VaccinationModel>> getVaccinations(String patientId) => _ds.getVaccinations(patientId);
  @override
  Future<VaccinationModel> addVaccination(VaccinationModel v) => _ds.addVaccination(v);
  @override
  Future<VaccinationModel> updateVaccination(VaccinationModel v) => _ds.updateVaccination(v);
  @override
  Future<void> deleteVaccination(String id) => _ds.deleteVaccination(id);
}
