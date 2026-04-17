import '../../data/datasources/patient_datasource.dart';
import '../../data/models/patient_model.dart';
import '../../domain/repositories/patient_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientDataSource _ds;
  PatientRepositoryImpl(this._ds);

  @override
  Future<List<PatientModel>> getPatients({required String doctorId, String? search}) =>
      _ds.getPatients(doctorId: doctorId, search: search);

  @override
  Future<PatientModel> getPatientById(String id) => _ds.getPatientById(id);

  @override
  Future<PatientModel> createPatient(PatientModel patient) => _ds.createPatient(patient);

  @override
  Future<PatientModel> updatePatient(PatientModel patient) => _ds.updatePatient(patient);

  @override
  Future<void> deletePatient(String id) => _ds.deletePatient(id);

  @override
  Future<List<PatientModel>> getPatientsByStatus({required String doctorId, required TreatmentStatus status}) =>
      _ds.getPatientsByStatus(doctorId: doctorId, status: status);
}
