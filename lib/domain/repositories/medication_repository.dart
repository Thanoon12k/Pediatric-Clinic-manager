import '../../data/models/medication_model.dart';

abstract class MedicationRepository {
  Future<List<MedicationModel>> getMedications(String doctorId);
  Future<MedicationModel> addMedication(MedicationModel medication);
  Future<MedicationModel> updateMedication(MedicationModel medication);
  Future<void> deleteMedication(String id);
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId);
  Future<PrescriptionModel> addPrescription(PrescriptionModel prescription);
  Future<void> deletePrescription(String id);
}
