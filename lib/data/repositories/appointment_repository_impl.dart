import '../../data/models/appointment_model.dart';
import '../../data/datasources/appointment_datasource.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentDataSource _ds;
  AppointmentRepositoryImpl(this._ds);

  @override Future<List<AppointmentModel>> getAppointments({required String doctorId, DateTime? date}) =>
      _ds.getAppointments(doctorId: doctorId, date: date);

  @override Future<List<AppointmentModel>> getPatientAppointments(String patientId) =>
      _ds.getPatientAppointments(patientId);

  @override Future<List<String>> getAvailableSlots({required String doctorId, required DateTime date}) =>
      _ds.getAvailableTimeSlots(doctorId: doctorId, date: date);

  @override Future<List<String>> getAvailableTimeSlots({required String doctorId, required DateTime date}) =>
      _ds.getAvailableTimeSlots(doctorId: doctorId, date: date);

  @override Future<AppointmentModel> bookAppointment(AppointmentModel appointment) =>
      _ds.createAppointment(appointment);

  @override Future<AppointmentModel> createAppointment(AppointmentModel appointment) =>
      _ds.createAppointment(appointment);

  @override Future<AppointmentModel> updateStatus({required String id, required AppointmentStatus status}) =>
      _ds.updateAppointmentStatus(id: id, status: status);

  @override Future<AppointmentModel> updateAppointmentStatus({required String id, required AppointmentStatus status, String? notes}) =>
      _ds.updateAppointmentStatus(id: id, status: status, notes: notes);

  @override Future<void> cancelAppointment(String id) => _ds.cancelAppointment(id);
}
