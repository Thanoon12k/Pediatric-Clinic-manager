import '../../data/models/patient_model.dart';

abstract class PatientRepository {
  Future<List<PatientModel>> getPatients({required String doctorId, String? search});
  Future<PatientModel> getPatientById(String id);
  Future<PatientModel> createPatient(PatientModel patient);
  Future<PatientModel> updatePatient(PatientModel patient);
  Future<void> deletePatient(String id);
  Future<List<PatientModel>> getPatientsByStatus({required String doctorId, required TreatmentStatus status});
}
