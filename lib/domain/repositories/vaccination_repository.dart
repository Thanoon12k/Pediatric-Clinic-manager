import '../../data/models/vaccination_model.dart';

abstract class VaccinationRepository {
  Future<List<VaccinationModel>> getVaccinations(String patientId);
  Future<VaccinationModel> addVaccination(VaccinationModel vaccination);
  Future<VaccinationModel> updateVaccination(VaccinationModel vaccination);
  Future<void> deleteVaccination(String id);
}
