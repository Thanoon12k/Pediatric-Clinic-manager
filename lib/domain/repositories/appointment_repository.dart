import '../../data/models/appointment_model.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getAppointments({required String doctorId, DateTime? date});
  Future<List<AppointmentModel>> getPatientAppointments(String patientId);
  Future<List<String>> getAvailableSlots({required String doctorId, required DateTime date});
  Future<List<String>> getAvailableTimeSlots({required String doctorId, required DateTime date});
  Future<AppointmentModel> bookAppointment(AppointmentModel appointment);
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<AppointmentModel> updateStatus({required String id, required AppointmentStatus status});
  Future<AppointmentModel> updateAppointmentStatus({required String id, required AppointmentStatus status, String? notes});
  Future<void> cancelAppointment(String id);
}
