import '../../data/datasources/doctor_datasource.dart';
import '../../data/models/doctor_model.dart';
import '../../domain/repositories/doctor_repository.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorDataSource _ds;
  DoctorRepositoryImpl(this._ds);

  @override Future<List<DoctorModel>> getAllDoctors() => _ds.getAllDoctors();
  @override Future<DoctorModel?> getDoctorByUserId(String userId) => _ds.getDoctorByUserId(userId);
  @override Future<DoctorModel?> getDoctorById(String id) async {
    try { return await _ds.getDoctorById(id); } catch (_) { return null; }
  }
  @override Future<DoctorModel> createDoctor(DoctorModel doctor) => _ds.createDoctor(doctor);
  @override Future<DoctorModel> updateDoctor(DoctorModel doctor) => _ds.updateDoctor(doctor);
  @override Future<void> deleteDoctor(String id) => _ds.deleteDoctor(id);
  @override Future<void> toggleDoctorStatus({required String id, required bool isActive}) =>
      _ds.toggleDoctorStatus(id, isActive);
}
