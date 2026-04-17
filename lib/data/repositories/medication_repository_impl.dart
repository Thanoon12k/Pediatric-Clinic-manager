import '../../data/datasources/medication_datasource.dart';
import '../../data/models/medication_model.dart';
import '../../domain/repositories/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationDataSource _ds;
  MedicationRepositoryImpl(this._ds);

  @override
  Future<List<MedicationModel>> getMedications(String doctorId) => _ds.getMedications(doctorId);
  @override
  Future<MedicationModel> addMedication(MedicationModel m) => _ds.addMedication(m);
  @override
  Future<MedicationModel> updateMedication(MedicationModel m) => _ds.updateMedication(m);
  @override
  Future<void> deleteMedication(String id) => _ds.deleteMedication(id);
  @override
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) => _ds.getPatientPrescriptions(patientId);
  @override
  Future<PrescriptionModel> addPrescription(PrescriptionModel p) => _ds.addPrescription(p);
  @override
  Future<void> deletePrescription(String id) => _ds.deletePrescription(id);
}
