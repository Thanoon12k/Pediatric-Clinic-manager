import '../../data/models/doctor_model.dart';

abstract class DoctorRepository {
  Future<List<DoctorModel>> getAllDoctors();
  Future<DoctorModel?> getDoctorByUserId(String userId);
  Future<DoctorModel?> getDoctorById(String id);
  Future<DoctorModel> createDoctor(DoctorModel doctor);
  Future<DoctorModel> updateDoctor(DoctorModel doctor);
  Future<void> deleteDoctor(String id);
  Future<void> toggleDoctorStatus({required String id, required bool isActive});
}
